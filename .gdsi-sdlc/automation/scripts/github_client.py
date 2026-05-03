#!/usr/bin/env python3
"""
GitHub Client - Wrapper around GitHub CLI for issue and project management

Uses the `gh` CLI tool for authentication and API access.
Generalized version for the gdsi-sdlc plugin.
"""

import subprocess
import json
from dataclasses import dataclass
from typing import Optional, List, Dict, Any
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


@dataclass
class GitHubIssue:
    """Represents a GitHub issue from the API."""

    number: int
    title: str
    body: str
    state: str
    labels: List[str]
    created_at: datetime
    updated_at: datetime
    node_id: Optional[str] = None
    state_reason: Optional[str] = (
        None  # "completed", "not_planned", "reopened", or None
    )
    project_status: Optional[str] = None
    project_priority: Optional[str] = None
    project_item_id: Optional[str] = None
    assignees: List[str] = None
    milestone: Optional[str] = None

    def __post_init__(self):
        if self.assignees is None:
            self.assignees = []


class GitHubClientError(Exception):
    """Custom exception for GitHub client errors."""

    pass


class GitHubClient:
    """Wrapper around GitHub CLI for issue and project management."""

    def __init__(
        self,
        owner: str,
        repo: str,
        project_number: Optional[int] = None,
        owner_type: Optional[str] = None,
    ):
        """
        Initialize the GitHub client.

        Args:
            owner: Repository owner (org or user)
            repo: Repository name
            project_number: GitHub Project number (optional)
            owner_type: 'user', 'org', or None for auto-detect
        """
        self.owner = owner
        self.repo = repo
        self.project_number = project_number
        self._owner_type: Optional[str] = owner_type
        self._project_id: Optional[str] = None
        self._status_field_id: Optional[str] = None
        self._status_options: Dict[str, str] = {}
        self._priority_field_id: Optional[str] = None
        self._priority_options: Dict[str, str] = {}

        self._verify_gh_cli()

    def _verify_gh_cli(self):
        """Verify GitHub CLI is installed and authenticated."""
        try:
            result = subprocess.run(
                ["gh", "auth", "status"], capture_output=True, text=True
            )
            if result.returncode != 0:
                raise GitHubClientError(
                    "GitHub CLI not authenticated. Run 'gh auth login' first."
                )
        except FileNotFoundError:
            raise GitHubClientError(
                "GitHub CLI not found. Install from https://cli.github.com/"
            )

    def _run_gh(self, args: List[str], input_data: str = None) -> str:
        """Execute GitHub CLI command."""
        cmd = ["gh"] + args
        logger.debug(f"Running: {' '.join(cmd)}")

        result = subprocess.run(cmd, capture_output=True, text=True, input=input_data)

        if result.returncode != 0:
            error_msg = result.stderr.strip() or result.stdout.strip()
            logger.error(f"gh command failed: {error_msg}")
            raise GitHubClientError(f"gh command failed: {error_msg}")

        return result.stdout

    def _run_graphql(self, query: str, variables: Dict[str, Any] = None) -> Dict:
        """Execute GraphQL query."""
        args = ["api", "graphql", "-f", f"query={query}"]

        if variables:
            for key, value in variables.items():
                if isinstance(value, int):
                    args.extend(["-F", f"{key}={value}"])
                elif value is not None:
                    args.extend(["-f", f"{key}={value}"])

        result = self._run_gh(args)
        data = json.loads(result)

        if "errors" in data:
            raise GitHubClientError(f"GraphQL error: {data['errors']}")

        return data.get("data", {})

    def _detect_owner_type(self) -> str:
        """Detect whether the owner is a user or organization."""
        if self._owner_type:
            return self._owner_type

        try:
            result = self._run_gh(["api", f"/users/{self.owner}"])
            data = json.loads(result)
            owner_type = data.get("type", "User")

            if owner_type == "Organization":
                self._owner_type = "org"
            else:
                self._owner_type = "user"

            logger.debug(f"Detected owner type for '{self.owner}': {self._owner_type}")

        except GitHubClientError:
            self._owner_type = "user"
            logger.debug(f"Could not detect owner type, defaulting to 'user'")

        return self._owner_type

    def get_project_id(self) -> str:
        """Get the GitHub Project V2 ID."""
        if self._project_id:
            return self._project_id

        if not self.project_number:
            raise GitHubClientError("Project number not configured")

        owner_type = self._detect_owner_type()

        if owner_type == "org":
            query = """
            query($owner: String!, $number: Int!) {
                organization(login: $owner) {
                    projectV2(number: $number) {
                        id
                    }
                }
            }
            """
            data = self._run_graphql(
                query, {"owner": self.owner, "number": self.project_number}
            )
            self._project_id = data["organization"]["projectV2"]["id"]
        else:
            query = """
            query($owner: String!, $number: Int!) {
                user(login: $owner) {
                    projectV2(number: $number) {
                        id
                    }
                }
            }
            """
            data = self._run_graphql(
                query, {"owner": self.owner, "number": self.project_number}
            )
            self._project_id = data["user"]["projectV2"]["id"]

        logger.info(f"Found project ID: {self._project_id}")
        return self._project_id

    def _get_status_field(self):
        """Get the Status field ID and options for the project."""
        if self._status_field_id:
            return

        query = """
        query($projectId: ID!) {
            node(id: $projectId) {
                ... on ProjectV2 {
                    fields(first: 20) {
                        nodes {
                            ... on ProjectV2SingleSelectField {
                                id
                                name
                                options {
                                    id
                                    name
                                }
                            }
                        }
                    }
                }
            }
        }
        """

        data = self._run_graphql(query, {"projectId": self.get_project_id()})

        for field in data.get("node", {}).get("fields", {}).get("nodes", []):
            if field and field.get("name") == "Status":
                self._status_field_id = field["id"]
                self._status_options = {
                    opt["name"]: opt["id"] for opt in field.get("options", [])
                }
                break

        if not self._status_field_id:
            logger.warning("Status field not found in project")

    def _get_priority_field(self):
        """Get the Priority field ID and options for the project."""
        if self._priority_field_id:
            return

        query = """
        query($projectId: ID!) {
            node(id: $projectId) {
                ... on ProjectV2 {
                    fields(first: 20) {
                        nodes {
                            ... on ProjectV2SingleSelectField {
                                id
                                name
                                options {
                                    id
                                    name
                                }
                            }
                        }
                    }
                }
            }
        }
        """

        data = self._run_graphql(query, {"projectId": self.get_project_id()})

        for field in data.get("node", {}).get("fields", {}).get("nodes", []):
            if field and field.get("name") == "Priority":
                self._priority_field_id = field["id"]
                self._priority_options = {
                    opt["name"]: opt["id"] for opt in field.get("options", [])
                }
                logger.debug(
                    f"Found Priority field with options: {list(self._priority_options.keys())}"
                )
                break

        if not self._priority_field_id:
            logger.warning("Priority field not found in project")

    def fetch_project_items(self) -> List[GitHubIssue]:
        """Fetch all issues from the project board."""
        query = """
        query($projectId: ID!, $cursor: String) {
            node(id: $projectId) {
                ... on ProjectV2 {
                    items(first: 100, after: $cursor) {
                        pageInfo {
                            hasNextPage
                            endCursor
                        }
                        nodes {
                            id
                            statusField: fieldValueByName(name: "Status") {
                                ... on ProjectV2ItemFieldSingleSelectValue {
                                    name
                                }
                            }
                            priorityField: fieldValueByName(name: "Priority") {
                                ... on ProjectV2ItemFieldSingleSelectValue {
                                    name
                                }
                            }
                            content {
                                ... on Issue {
                                    number
                                    title
                                    body
                                    state
                                    createdAt
                                    updatedAt
                                    labels(first: 20) {
                                        nodes { name }
                                    }
                                    assignees(first: 10) {
                                        nodes { login }
                                    }
                                    milestone {
                                        title
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        """

        project_id = self.get_project_id()
        all_items = []
        cursor = None

        while True:
            data = self._run_graphql(query, {"projectId": project_id, "cursor": cursor})

            items = data.get("node", {}).get("items", {})

            for item in items.get("nodes", []):
                if not item or not item.get("content"):
                    continue

                content = item["content"]
                status_field = item.get("statusField")
                priority_field = item.get("priorityField")

                all_items.append(
                    GitHubIssue(
                        number=content["number"],
                        title=content["title"],
                        body=content.get("body") or "",
                        state=content["state"].lower(),
                        labels=[
                            l["name"]
                            for l in content.get("labels", {}).get("nodes", [])
                        ],
                        created_at=datetime.fromisoformat(
                            content["createdAt"].replace("Z", "+00:00")
                        ),
                        updated_at=datetime.fromisoformat(
                            content["updatedAt"].replace("Z", "+00:00")
                        ),
                        project_status=status_field.get("name")
                        if status_field
                        else None,
                        project_priority=priority_field.get("name")
                        if priority_field
                        else None,
                        project_item_id=item["id"],
                        assignees=[
                            a["login"]
                            for a in content.get("assignees", {}).get("nodes", [])
                        ],
                        milestone=content.get("milestone", {}).get("title")
                        if content.get("milestone")
                        else None,
                    )
                )

            page_info = items.get("pageInfo", {})
            if not page_info.get("hasNextPage"):
                break
            cursor = page_info.get("endCursor")

        logger.info(f"Fetched {len(all_items)} items from project")
        return all_items

    def fetch_repo_issues(self, state: str = "open") -> List[GitHubIssue]:
        """Fetch issues directly from the repository."""
        args = [
            "issue",
            "list",
            "--repo",
            f"{self.owner}/{self.repo}",
            "--state",
            state,
            "--limit",
            "1000",
            "--json",
            "number,title,body,state,stateReason,labels,createdAt,updatedAt,assignees,milestone",
        ]

        result = self._run_gh(args)
        issues = json.loads(result)

        return [
            GitHubIssue(
                number=issue["number"],
                title=issue["title"],
                body=issue.get("body") or "",
                state=issue["state"].lower(),
                state_reason=issue.get(
                    "stateReason"
                ),  # "completed", "not_planned", "reopened", or None
                labels=[l["name"] for l in issue.get("labels", [])],
                created_at=datetime.fromisoformat(
                    issue["createdAt"].replace("Z", "+00:00")
                ),
                updated_at=datetime.fromisoformat(
                    issue["updatedAt"].replace("Z", "+00:00")
                ),
                assignees=[a["login"] for a in issue.get("assignees", [])],
                milestone=issue.get("milestone", {}).get("title")
                if issue.get("milestone")
                else None,
            )
            for issue in issues
        ]

    def create_issue(self, title: str, body: str, labels: List[str] = None) -> int:
        """Create a new GitHub issue."""
        args = [
            "issue",
            "create",
            "--repo",
            f"{self.owner}/{self.repo}",
            "--title",
            title,
            "--body",
            body,
        ]

        result = self._run_gh(args)
        url = result.strip()
        issue_number = int(url.split("/")[-1])

        logger.info(f"Created issue #{issue_number}: {title}")

        if labels:
            self._ensure_labels_exist(labels)
            try:
                self._run_gh(
                    [
                        "issue",
                        "edit",
                        str(issue_number),
                        "--repo",
                        f"{self.owner}/{self.repo}",
                        "--add-label",
                        ",".join(labels),
                    ]
                )
                logger.debug(f"Added labels to issue #{issue_number}: {labels}")
            except GitHubClientError as e:
                logger.warning(f"Could not add labels to issue #{issue_number}: {e}")

        return issue_number

    def _ensure_labels_exist(self, labels: List[str]):
        """Ensure labels exist in the repository, creating them if needed."""
        colors = {
            "P0": "b60205",
            "P1": "d93f0b",
            "P2": "fbca04",
            "P3": "0e8a16",
            "REQ": "1d76db",
            "FIX": "d73a4a",
            "DOC": "0075ca",
            "TST": "7057ff",
            "REF": "5319e7",
            "INF": "3c6f48",
            "REL": "006b75",
        }

        for label in labels:
            color = colors.get(label, "ededed")
            try:
                self._run_gh(
                    [
                        "label",
                        "create",
                        label,
                        "--repo",
                        f"{self.owner}/{self.repo}",
                        "--color",
                        color,
                        "--force",
                    ]
                )
                logger.debug(f"Ensured label exists: {label}")
            except GitHubClientError:
                pass

    def update_issue(
        self,
        number: int,
        title: str = None,
        body: str = None,
        state: str = None,
        add_labels: List[str] = None,
        remove_labels: List[str] = None,
    ):
        """Update an existing GitHub issue."""
        args = ["issue", "edit", str(number), "--repo", f"{self.owner}/{self.repo}"]

        if title:
            args.extend(["--title", title])
        if body:
            args.extend(["--body", body])
        if add_labels:
            args.extend(["--add-label", ",".join(add_labels)])
        if remove_labels:
            args.extend(["--remove-label", ",".join(remove_labels)])

        if len(args) > 4:
            self._run_gh(args)

        if state:
            state_cmd = "reopen" if state.lower() == "open" else "close"
            self._run_gh(
                ["issue", state_cmd, str(number), "--repo", f"{self.owner}/{self.repo}"]
            )

        logger.info(f"Updated issue #{number}")

    def add_to_project(self, issue_number: int) -> str:
        """Add an issue to the project board."""
        result = self._run_gh(
            ["api", f"/repos/{self.owner}/{self.repo}/issues/{issue_number}"]
        )
        issue_data = json.loads(result)
        issue_node_id = issue_data["node_id"]

        mutation = """
        mutation($projectId: ID!, $contentId: ID!) {
            addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) {
                item {
                    id
                }
            }
        }
        """

        data = self._run_graphql(
            mutation, {"projectId": self.get_project_id(), "contentId": issue_node_id}
        )

        item_id = data["addProjectV2ItemById"]["item"]["id"]
        logger.info(f"Added issue #{issue_number} to project (item: {item_id})")
        return item_id

    def update_project_status(self, item_id: str, status: str):
        """Update the status of an item on the project board."""
        self._get_status_field()

        if not self._status_field_id:
            logger.warning("Cannot update status: Status field not found")
            return

        option_id = self._status_options.get(status)
        if not option_id:
            logger.warning(f"Status '{status}' not found in project options")
            return

        mutation = """
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
            updateProjectV2ItemFieldValue(input: {
                projectId: $projectId
                itemId: $itemId
                fieldId: $fieldId
                value: {
                    singleSelectOptionId: $optionId
                }
            }) {
                projectV2Item {
                    id
                }
            }
        }
        """

        self._run_graphql(
            mutation,
            {
                "projectId": self.get_project_id(),
                "itemId": item_id,
                "fieldId": self._status_field_id,
                "optionId": option_id,
            },
        )

        logger.info(f"Updated project item {item_id} status to '{status}'")

    def update_project_priority(self, item_id: str, priority: str) -> bool:
        """Update the priority of an item on the project board."""
        self._get_priority_field()

        if not self._priority_field_id:
            logger.warning(
                "Cannot update priority: Priority field not found in project"
            )
            return False

        gh_priority = priority.upper() if priority else None

        # Try exact match first, then prefix match (e.g., "P0" matches "P0 - Critical")
        option_id = self._priority_options.get(gh_priority) if gh_priority else None
        if not option_id and gh_priority:
            for opt_name, opt_id in self._priority_options.items():
                if opt_name.upper().startswith(gh_priority):
                    option_id = opt_id
                    logger.debug(
                        f"Priority '{gh_priority}' matched to '{opt_name}' via prefix"
                    )
                    break

        if gh_priority and not option_id:
            logger.info(
                f"Priority '{gh_priority}' not in project options, clearing field"
            )
            mutation = """
            mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!) {
                clearProjectV2ItemFieldValue(input: {
                    projectId: $projectId
                    itemId: $itemId
                    fieldId: $fieldId
                }) {
                    projectV2Item {
                        id
                    }
                }
            }
            """
            try:
                self._run_graphql(
                    mutation,
                    {
                        "projectId": self.get_project_id(),
                        "itemId": item_id,
                        "fieldId": self._priority_field_id,
                    },
                )
                logger.info(f"Cleared priority for project item {item_id}")
                return True
            except GitHubClientError as e:
                logger.warning(f"Could not clear priority: {e}")
                return False

        if not option_id:
            logger.warning(f"Priority '{gh_priority}' not found in project options")
            return False

        mutation = """
        mutation($projectId: ID!, $itemId: ID!, $fieldId: ID!, $optionId: String!) {
            updateProjectV2ItemFieldValue(input: {
                projectId: $projectId
                itemId: $itemId
                fieldId: $fieldId
                value: {
                    singleSelectOptionId: $optionId
                }
            }) {
                projectV2Item {
                    id
                }
            }
        }
        """

        try:
            self._run_graphql(
                mutation,
                {
                    "projectId": self.get_project_id(),
                    "itemId": item_id,
                    "fieldId": self._priority_field_id,
                    "optionId": option_id,
                },
            )
            logger.info(f"Updated project item {item_id} priority to '{gh_priority}'")
            return True
        except GitHubClientError as e:
            logger.warning(f"Could not update priority: {e}")
            return False

    def close_issue(self, number: int, reason: str = None):
        """Close an issue."""
        args = ["issue", "close", str(number), "--repo", f"{self.owner}/{self.repo}"]

        if reason:
            args.extend(["--comment", reason])

        self._run_gh(args)
        logger.info(f"Closed issue #{number}")

    def reopen_issue(self, number: int):
        """Reopen a closed issue."""
        self._run_gh(
            ["issue", "reopen", str(number), "--repo", f"{self.owner}/{self.repo}"]
        )
        logger.info(f"Reopened issue #{number}")


if __name__ == "__main__":
    import sys

    if len(sys.argv) >= 3:
        owner = sys.argv[1]
        repo = sys.argv[2]
        project = int(sys.argv[3]) if len(sys.argv) > 3 else None

        client = GitHubClient(owner, repo, project)

        if project:
            print(f"Project ID: {client.get_project_id()}")
            items = client.fetch_project_items()
            print(f"Found {len(items)} project items")
            for item in items[:5]:
                print(f"  #{item.number}: {item.title} [{item.project_status}]")
        else:
            issues = client.fetch_repo_issues()
            print(f"Found {len(issues)} open issues")
            for issue in issues[:5]:
                print(f"  #{issue.number}: {issue.title}")
    else:
        print("Usage: python github_client.py <owner> <repo> [project_number]")
