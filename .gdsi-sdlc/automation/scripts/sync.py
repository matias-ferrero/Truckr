#!/usr/bin/env python3
"""
GitHub Issues Sync Engine

Bidirectional synchronization between GitHub Issues/Projects and local .issue.md files.
Generalized version for the gdsi-sdlc plugin.

Usage:
    python sync.py sync [--dry-run] [--direction=bidirectional]
    python sync.py status
    python sync.py init
"""

import json
import hashlib
import logging
import re
import sys
from pathlib import Path
from datetime import datetime, timezone
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum

# Add parent directory for local imports
sys.path.insert(0, str(Path(__file__).parent))

from config_loader import ConfigLoader, get_config
from github_client import GitHubClient, GitHubIssue, GitHubClientError
from issue_parser import IssueParser, LocalIssue

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
logger = logging.getLogger(__name__)


class SyncDirection(Enum):
    """Sync direction options."""

    BIDIRECTIONAL = "bidirectional"
    GITHUB_TO_LOCAL = "github-to-local"
    LOCAL_TO_GITHUB = "local-to-github"


class ActionType(Enum):
    """Types of sync actions."""

    CREATE_LOCAL = "create_local"
    CREATE_GITHUB = "create_github"
    UPDATE_LOCAL = "update_local"
    UPDATE_GITHUB = "update_github"
    MOVE_LOCAL = "move_local"
    MOVE_GITHUB = "move_github"
    TOMBSTONE = "tombstone"
    CONFLICT = "conflict"
    SKIP = "skip"
    IMPORT_UNTAGGED = "import_untagged"
    ADD_TO_PROJECT = "add_to_project"


# Lifecycle ordering for forward-only status sync guardrail.
# Automatic sync will only move issues forward in this order;
# backward moves are skipped with a warning, requiring manual intervention.
STATUS_ORDER = {
    "backlog": 0,
    "ready": 1,
    "in_progress": 2,
    "in_review": 3,
    "done": 4,
}


@dataclass
class SyncAction:
    """Represents a sync action to be performed."""

    action: ActionType
    tag: str
    details: str
    github_issue: Optional[GitHubIssue] = None
    local_issue: Optional[LocalIssue] = None
    priority: int = 0


@dataclass
class SyncState:
    """Tracks sync state between runs."""

    version: str = "1.0"
    last_sync: Optional[str] = None
    project: Dict = field(default_factory=dict)
    issues: Dict = field(default_factory=dict)
    tombstones: Dict = field(default_factory=dict)

    @classmethod
    def load(cls, path: Path) -> "SyncState":
        """Load state from file."""
        if path.exists():
            data = json.loads(path.read_text())
            return cls(
                version=data.get("version", "1.0"),
                last_sync=data.get("last_sync"),
                project=data.get("project", {}),
                issues=data.get("issues", {}),
                tombstones=data.get("tombstones", {}),
            )
        return cls()

    def save(self, path: Path):
        """Save state to file."""
        data = {
            "version": self.version,
            "last_sync": self.last_sync,
            "project": self.project,
            "issues": self.issues,
            "tombstones": self.tombstones,
        }
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(data, indent=2))


class SyncEngine:
    """Bidirectional sync engine for GitHub issues and local files."""

    def __init__(self, repo_root: Path = None):
        """Initialize the sync engine."""
        self.config_loader = ConfigLoader(repo_root)
        self.repo_root = self.config_loader.repo_root
        self.config = self.config_loader.load()
        self.state = self._load_state()
        self.actions: List[SyncAction] = []
        self.dry_run = False
        self.project_available = True

        # Initialize GitHub client
        self.github = GitHubClient(
            owner=self.config.github.owner,
            repo=self.config.github.repo,
            project_number=self.config.github.project_number,
            owner_type=self.config.github.owner_type,
        )

        # Local paths from config
        self.base_path = self.config_loader.get_issues_base_path()
        self.docs_path = self.config_loader.get_features_path()

    def _load_state(self) -> SyncState:
        """Load sync state."""
        state_path = self.config_loader.get_automation_path() / ".sync-state.json"
        return SyncState.load(state_path)

    def _save_state(self):
        """Save sync state."""
        state_path = self.config_loader.get_automation_path() / ".sync-state.json"
        self.state.last_sync = datetime.now(timezone.utc).isoformat() + "Z"
        self.state.project = {
            "owner": self.config.github.owner,
            "repo": self.config.github.repo,
            "project_number": self.config.github.project_number,
        }
        self.state.save(state_path)

    def sync(
        self,
        direction: SyncDirection = SyncDirection.BIDIRECTIONAL,
        dry_run: bool = False,
        force: bool = False,
    ) -> List[SyncAction]:
        """Execute bidirectional sync."""
        logger.info(f"Starting sync (direction: {direction.value}, dry_run: {dry_run})")
        self.actions = []
        self.dry_run = dry_run
        self.project_available = True

        try:
            # Phase 1: Fetch all states
            github_issues, untagged_issues = self._fetch_github_state()
            local_issues = self._fetch_local_state()

            # Phase 2: Reconcile tagged issues
            self._reconcile(github_issues, local_issues, direction, force)

            # Phase 3: Handle untagged GitHub issues
            if direction in [
                SyncDirection.BIDIRECTIONAL,
                SyncDirection.GITHUB_TO_LOCAL,
            ]:
                self._queue_untagged_imports(untagged_issues, local_issues)

            # Sort actions by priority
            self.actions.sort(key=lambda a: (a.priority, a.tag))

            # Phase 4: Apply or preview
            if dry_run:
                self._print_actions()
            else:
                self._apply_actions()
                self._save_state()

            logger.info(
                f"Sync complete. {len(self.actions)} actions "
                f"{'would be ' if dry_run else ''}performed."
            )

        except GitHubClientError as e:
            logger.error(f"GitHub API error: {e}")
            raise
        except Exception as e:
            logger.error(f"Sync error: {e}")
            raise

        return self.actions

    def _fetch_github_state(self) -> Tuple[Dict[str, GitHubIssue], List[GitHubIssue]]:
        """Fetch all issues from GitHub repository, optionally filtered by project membership."""
        repo_issues = []
        try:
            repo_issues = self.github.fetch_repo_issues(state="all")
            logger.info(f"Fetched {len(repo_issues)} issues from repository")
        except GitHubClientError as e:
            logger.warning(f"Could not fetch repo issues: {e}")

        issues_by_number = {issue.number: issue for issue in repo_issues}

        # Track which issue numbers belong to the configured project
        project_issue_numbers: set = set()

        if self.github.project_number:
            try:
                project_items = self.github.fetch_project_items()
                logger.info(f"Fetched {len(project_items)} items from GitHub Project")

                for proj_item in project_items:
                    project_issue_numbers.add(proj_item.number)
                    if proj_item.number in issues_by_number:
                        issues_by_number[
                            proj_item.number
                        ].project_status = proj_item.project_status
                        issues_by_number[
                            proj_item.number
                        ].project_priority = proj_item.project_priority
                        issues_by_number[
                            proj_item.number
                        ].project_item_id = proj_item.project_item_id
            except GitHubClientError as e:
                logger.warning(f"Could not fetch project items: {e}")
                self.project_available = False

        # Apply project-scoped filtering if enabled
        project_scoped = self.config.sync.project_scoped and bool(project_issue_numbers)
        if project_scoped:
            total_before = len(issues_by_number)
            issues_by_number = {
                num: issue
                for num, issue in issues_by_number.items()
                if num in project_issue_numbers
            }
            filtered_count = total_before - len(issues_by_number)
            if filtered_count > 0:
                logger.info(
                    f"Project-scoped filter: kept {len(issues_by_number)} issues in project, "
                    f"filtered out {filtered_count} issues from other projects"
                )

        tagged = {}
        untagged = []
        for issue in issues_by_number.values():
            # Skip issues closed as "not planned" (duplicates, won't fix, etc.)
            if issue.state == "closed" and issue.state_reason == "not_planned":
                logger.debug(
                    f"Skipping closed (not planned) issue #{issue.number}: {issue.title}"
                )
                continue

            tag, _ = IssueParser.extract_tag_from_title(issue.title)
            if tag:
                if not IssueParser.is_valid_tag(tag):
                    logger.warning(
                        f"Issue #{issue.number} has invalid TAG format: '{tag}' - treating as untagged"
                    )
                    untagged.append(issue)
                    continue
                tagged[tag] = issue
            else:
                untagged.append(issue)
                logger.debug(f"Found untagged issue #{issue.number}: {issue.title}")

        logger.info(
            f"Found {len(tagged)} tagged issues, {len(untagged)} untagged issues from GitHub"
        )
        return tagged, untagged

    def _fetch_local_state(self) -> Dict[str, LocalIssue]:
        """Scan all local issue files."""
        folders = list(self.config.status_mapping.values())
        result = IssueParser.scan_all_folders(self.base_path, folders)
        logger.info(f"Found {len(result)} local issues")
        return result

    def _queue_untagged_imports(
        self, untagged_issues: List[GitHubIssue], local_issues: Dict[str, LocalIssue]
    ):
        """Queue import actions for untagged GitHub issues."""
        assigned_tags = set(local_issues.keys()) | set(self.state.issues.keys())

        for issue in untagged_issues:
            tag = self._generate_tag_for_issue(issue, local_issues, assigned_tags)
            assigned_tags.add(tag)

            self.actions.append(
                SyncAction(
                    action=ActionType.IMPORT_UNTAGGED,
                    tag=tag,
                    details=f"Import GitHub issue #{issue.number} and assign TAG [{tag}]",
                    github_issue=issue,
                    priority=0,
                )
            )

    def _generate_tag_for_issue(
        self,
        issue: GitHubIssue,
        local_issues: Dict[str, LocalIssue],
        assigned_tags: set = None,
    ) -> str:
        """Generate an appropriate TAG for an untagged GitHub issue."""
        if assigned_tags is None:
            assigned_tags = set()

        title_lower = issue.title.lower()
        body_lower = (issue.body or "").lower()

        # Determine PREFIX
        prefix = self.config.issues.default_prefix

        if any(
            word in title_lower for word in ["fix", "bug", "error", "issue", "broken"]
        ):
            prefix = "FIX"
        elif any(label.lower() in ["bug", "fix"] for label in issue.labels):
            prefix = "FIX"
        elif any(
            word in title_lower for word in ["ci", "cd", "pipeline", "deploy", "infra"]
        ):
            prefix = "INF"
        elif any(
            word in title_lower for word in ["doc", "readme", "guide", "documentation"]
        ):
            prefix = "DOC"
        elif any(
            word in title_lower
            for word in ["test", "e2e", "integration test", "unit test"]
        ):
            prefix = "TST"

        # Determine SCOPE
        scope = self.config.issues.default_scope

        for s in self.config.issues.scopes:
            if s.lower() in title_lower or s.lower() in body_lower:
                scope = s
                break

        # Find next available number
        existing_numbers = set()
        for tag in assigned_tags:
            try:
                p, s, n = IssueParser.parse_tag(tag)
                if p == prefix and s == scope:
                    existing_numbers.add(int(n))
            except ValueError, TypeError:
                pass

        next_number = 1
        while next_number in existing_numbers:
            next_number += 1

        return f"{prefix}-{scope}-{next_number:05d}"

    def _reconcile(
        self,
        github_issues: Dict[str, GitHubIssue],
        local_issues: Dict[str, LocalIssue],
        direction: SyncDirection,
        force: bool,
    ):
        """Reconcile GitHub and local states."""
        all_tags = set(github_issues.keys()) | set(local_issues.keys())

        for tag in all_tags:
            gh = github_issues.get(tag)
            local = local_issues.get(tag)

            if gh and not local:
                if direction in [
                    SyncDirection.BIDIRECTIONAL,
                    SyncDirection.GITHUB_TO_LOCAL,
                ]:
                    self.actions.append(
                        SyncAction(
                            action=ActionType.CREATE_LOCAL,
                            tag=tag,
                            details=f"Create local file from GitHub issue #{gh.number}",
                            github_issue=gh,
                            priority=1,
                        )
                    )

            elif local and not gh:
                if direction in [
                    SyncDirection.BIDIRECTIONAL,
                    SyncDirection.LOCAL_TO_GITHUB,
                ]:
                    if IssueParser.is_unassigned_tag(tag):
                        logger.debug(f"Skipping unassigned tag {tag}")
                        continue

                    self.actions.append(
                        SyncAction(
                            action=ActionType.CREATE_GITHUB,
                            tag=tag,
                            details=f"Create GitHub issue from local file",
                            local_issue=local,
                            priority=1,
                        )
                    )

            else:
                self._reconcile_existing(tag, gh, local, direction, force)

                if (
                    self.github.project_number
                    and self.project_available
                    and not gh.project_item_id
                ):
                    self.actions.append(
                        SyncAction(
                            action=ActionType.ADD_TO_PROJECT,
                            tag=tag,
                            details=f"Add issue #{gh.number} to project board",
                            github_issue=gh,
                            local_issue=local,
                            priority=4,
                        )
                    )

    def _reconcile_existing(
        self,
        tag: str,
        gh: GitHubIssue,
        local: LocalIssue,
        direction: SyncDirection,
        force: bool,
    ):
        """Reconcile an issue that exists in both places."""
        state = self.state.issues.get(tag, {})

        local_hash = IssueParser.compute_hash(local)
        gh_hash = self._compute_github_hash(gh)

        local_changed = local_hash != state.get("local_hash")
        gh_changed = gh_hash != state.get("github_hash")

        if local_changed and gh_changed and not force:
            self.actions.append(
                SyncAction(
                    action=ActionType.CONFLICT,
                    tag=tag,
                    details="Both GitHub and local have changed since last sync",
                    github_issue=gh,
                    local_issue=local,
                    priority=0,
                )
            )
            return

        if gh_changed and direction in [
            SyncDirection.BIDIRECTIONAL,
            SyncDirection.GITHUB_TO_LOCAL,
        ]:
            self.actions.append(
                SyncAction(
                    action=ActionType.UPDATE_LOCAL,
                    tag=tag,
                    details=f"Update local from GitHub (issue #{gh.number})",
                    github_issue=gh,
                    local_issue=local,
                    priority=2,
                )
            )

        if local_changed and direction in [
            SyncDirection.BIDIRECTIONAL,
            SyncDirection.LOCAL_TO_GITHUB,
        ]:
            self.actions.append(
                SyncAction(
                    action=ActionType.UPDATE_GITHUB,
                    tag=tag,
                    details=f"Update GitHub issue #{gh.number} from local",
                    github_issue=gh,
                    local_issue=local,
                    priority=2,
                )
            )

        self._check_status_sync(tag, gh, local, direction)

    def _compute_github_hash(self, issue: GitHubIssue) -> str:
        """Compute hash from GitHub issue content."""
        _, title = IssueParser.extract_tag_from_title(issue.title)
        content = f"{title}|{issue.body}"
        return hashlib.sha256(content.encode()).hexdigest()[:16]

    def _is_forward_transition(self, from_status: str, to_status: str) -> bool:
        """Check if a status transition moves forward in the lifecycle.

        Returns True if the transition is forward or lateral (same ordinal),
        or if either status is unknown (safe fallback).
        Returns False only for confirmed backward moves.
        """
        from_ord = STATUS_ORDER.get(from_status.lower())
        to_ord = STATUS_ORDER.get(to_status.lower())
        if from_ord is None or to_ord is None:
            return True  # Unknown status → allow (safe fallback)
        return to_ord >= from_ord

    def _check_status_sync(
        self, tag: str, gh: GitHubIssue, local: LocalIssue, direction: SyncDirection
    ):
        """Check if status needs syncing between GitHub and local.

        In bidirectional mode, uses timestamp-based versioning:
        - If GitHub change is newer → move local to match GitHub
        - If local change is newer → update GitHub to match local
        """
        gh_status = self._map_github_status(gh.project_status)
        local_status = local.status.lower()

        if gh_status and gh_status != local_status:
            if direction == SyncDirection.LOCAL_TO_GITHUB:
                # local → GitHub: target is local_status, current is gh_status
                if not self._is_forward_transition(gh_status, local_status):
                    logger.warning(
                        f"Skipping backward status move for {tag}: "
                        f"GitHub is '{gh_status}' but local is '{local_status}'. "
                        f"Move the local file forward manually if intended."
                    )
                    return
                self.actions.append(
                    SyncAction(
                        action=ActionType.MOVE_GITHUB,
                        tag=tag,
                        details=f"Update GitHub project status to {self._map_local_status(local_status)}",
                        github_issue=gh,
                        local_issue=local,
                        priority=3,
                    )
                )
            elif direction == SyncDirection.GITHUB_TO_LOCAL:
                # GitHub → local: target is gh_status, current is local_status
                if not self._is_forward_transition(local_status, gh_status):
                    logger.warning(
                        f"Skipping backward status move for {tag}: "
                        f"local is '{local_status}' but GitHub is '{gh_status}'. "
                        f"Update GitHub status forward manually if intended."
                    )
                    return
                self.actions.append(
                    SyncAction(
                        action=ActionType.MOVE_LOCAL,
                        tag=tag,
                        details=f"Move local file to {gh_status} folder",
                        github_issue=gh,
                        local_issue=local,
                        priority=3,
                    )
                )
            elif direction == SyncDirection.BIDIRECTIONAL:
                # Bidirectional: use timestamp-based versioning
                github_wins = self._compare_timestamps(gh, local)
                if github_wins:
                    # GitHub → local: target is gh_status, current is local_status
                    if not self._is_forward_transition(local_status, gh_status):
                        logger.warning(
                            f"Skipping backward status move for {tag}: "
                            f"local is '{local_status}' but GitHub is '{gh_status}'. "
                            f"Update GitHub status forward manually if intended."
                        )
                        return
                    self.actions.append(
                        SyncAction(
                            action=ActionType.MOVE_LOCAL,
                            tag=tag,
                            details=f"Move local file to {gh_status} folder (GitHub updated more recently)",
                            github_issue=gh,
                            local_issue=local,
                            priority=3,
                        )
                    )
                else:
                    # local → GitHub: target is local_status, current is gh_status
                    if not self._is_forward_transition(gh_status, local_status):
                        logger.warning(
                            f"Skipping backward status move for {tag}: "
                            f"GitHub is '{gh_status}' but local is '{local_status}'. "
                            f"Move the local file forward manually if intended."
                        )
                        return
                    self.actions.append(
                        SyncAction(
                            action=ActionType.MOVE_GITHUB,
                            tag=tag,
                            details=f"Update GitHub project status to {self._map_local_status(local_status)} (local updated more recently)",
                            github_issue=gh,
                            local_issue=local,
                            priority=3,
                        )
                    )

    def _compare_timestamps(self, gh: GitHubIssue, local: LocalIssue) -> bool:
        """Compare GitHub and local timestamps to determine which is newer.

        Returns True if GitHub is newer (GitHub wins), False if local is newer.
        """
        try:
            if local.file_path and local.file_path.exists():
                local_mtime = datetime.fromtimestamp(
                    local.file_path.stat().st_mtime, tz=timezone.utc
                )
            else:
                return True  # No local file, GitHub wins

            gh_updated = gh.updated_at
            if gh_updated.tzinfo is None:
                gh_updated = gh_updated.replace(tzinfo=timezone.utc)

            github_wins = gh_updated > local_mtime
            logger.debug(
                f"Timestamp comparison for {local.tag}: "
                f"GitHub={gh_updated.isoformat()}, Local={local_mtime.isoformat()}, "
                f"Winner={'GitHub' if github_wins else 'Local'}"
            )
            return github_wins
        except Exception as e:
            logger.warning(
                f"Error comparing timestamps for {local.tag}: {e}, defaulting to GitHub"
            )
            return True

    def _map_github_status(self, status: Optional[str]) -> Optional[str]:
        """Map GitHub project status to local status."""
        if not status:
            return None

        for gh_status, folder in self.config.status_mapping.items():
            if gh_status == status:
                return IssueParser.get_status_from_folder(folder)

        return None

    def _map_local_status(self, status: str) -> str:
        """Map local status to GitHub project status."""
        folder = IssueParser.get_status_folder(status, Path("")).name
        return self.config.folder_to_status.get(folder, "Backlog")

    def _apply_actions(self):
        """Apply all pending sync actions."""
        failed_actions: List[str] = []

        for action in self.actions:
            try:
                logger.info(
                    f"[{action.action.value.upper()}] {action.tag}: {action.details}"
                )

                if action.action == ActionType.CREATE_LOCAL:
                    self._create_local_issue(action)
                elif action.action == ActionType.CREATE_GITHUB:
                    self._create_github_issue(action)
                elif action.action == ActionType.UPDATE_LOCAL:
                    self._update_local_issue(action)
                elif action.action == ActionType.UPDATE_GITHUB:
                    self._update_github_issue(action)
                elif action.action == ActionType.MOVE_LOCAL:
                    self._move_local_issue(action)
                elif action.action == ActionType.MOVE_GITHUB:
                    self._move_github_issue(action)
                elif action.action == ActionType.CONFLICT:
                    self._handle_conflict(action)
                elif action.action == ActionType.IMPORT_UNTAGGED:
                    self._import_untagged_issue(action)
                elif action.action == ActionType.ADD_TO_PROJECT:
                    self._add_issue_to_project(action)

            except Exception as e:
                logger.error(f"Error applying action for {action.tag}: {e}")
                failed_actions.append(f"{action.tag}: {e}")

        if failed_actions:
            logger.error(f"Sync completed with {len(failed_actions)} failures:")
            for failure in failed_actions:
                logger.error(f"  - {failure}")
            raise RuntimeError(
                f"Sync had {len(failed_actions)} failures. See log above."
            )

    def _create_local_issue(self, action: SyncAction):
        """Create a local .issue.md file from GitHub issue."""
        gh = action.github_issue
        tag, title = IssueParser.extract_tag_from_title(gh.title)

        priority = self.config.issues.default_priority
        for label in gh.labels:
            if label.upper() in ["P0", "P1", "P2", "P3"]:
                priority = label.upper()
                break

        status = self._map_github_status(gh.project_status) or "backlog"

        issue = LocalIssue(
            tag=tag,
            title=title,
            priority=priority,
            status=status,
            created=gh.created_at.strftime("%Y-%m-%d"),
            source="github",
            source_url=f"https://github.com/{self.github.owner}/{self.github.repo}/issues/{gh.number}",
            github_issue=gh.number,
            github_project_item=gh.project_item_id,
            github_repo=f"{self.github.owner}/{self.github.repo}",
            labels=[l for l in gh.labels if l.upper() not in ["P0", "P1", "P2", "P3"]],
            assignees=gh.assignees,
            content=gh.body,
            last_synced=datetime.now(timezone.utc).isoformat() + "Z",
        )

        folder = IssueParser.get_status_folder(status, self.base_path)
        filename = IssueParser.generate_filename(tag, title)
        path = folder / filename

        IssueParser.write_file(issue, path)
        logger.info(f"  Created: {path.relative_to(self.repo_root)}")

        self.state.issues[tag] = {
            "github_issue": gh.number,
            "github_project_item": gh.project_item_id,
            "local_path": str(path.relative_to(self.repo_root)),
            "local_hash": IssueParser.compute_hash(issue),
            "github_hash": self._compute_github_hash(gh),
            "last_synced": datetime.now(timezone.utc).isoformat() + "Z",
            "status": "synced",
        }

    def _create_github_issue(self, action: SyncAction):
        """Create a GitHub issue from local file."""
        local = action.local_issue

        title = IssueParser.format_github_title(local.tag, local.title)

        labels = list(local.labels or [])
        labels.append(local.priority)

        try:
            prefix, scope, _ = IssueParser.parse_tag(local.tag)
            labels.append(prefix)
            labels.append(scope)
        except ValueError:
            pass

        issue_number = self.github.create_issue(
            title=title, body=local.content, labels=labels
        )

        project_item_id = None
        if self.github.project_number:
            try:
                project_item_id = self.github.add_to_project(issue_number)

                gh_status = self._map_local_status(local.status)
                if project_item_id and gh_status:
                    self.github.update_project_status(project_item_id, gh_status)

                if project_item_id and local.priority:
                    self.github.update_project_priority(project_item_id, local.priority)
            except GitHubClientError as e:
                logger.warning(f"Could not add to project: {e}")

        local.github_issue = issue_number
        local.github_project_item = project_item_id
        local.github_repo = f"{self.github.owner}/{self.github.repo}"
        local.last_synced = datetime.now(timezone.utc).isoformat() + "Z"
        local.source_url = f"https://github.com/{self.github.owner}/{self.github.repo}/issues/{issue_number}"
        IssueParser.write_file(local, local.file_path)

        logger.info(f"  Created GitHub issue #{issue_number}")

        # Compute github_hash from what we just pushed (title + body)
        github_hash = hashlib.sha256(
            f"{local.title}|{local.content}".encode()
        ).hexdigest()[:16]

        self.state.issues[local.tag] = {
            "github_issue": issue_number,
            "github_project_item": project_item_id,
            "local_path": str(local.file_path.relative_to(self.repo_root)),
            "local_hash": IssueParser.compute_hash(local),
            "github_hash": github_hash,
            "last_synced": datetime.now(timezone.utc).isoformat() + "Z",
            "status": "synced",
        }

    def _update_local_issue(self, action: SyncAction):
        """Update local file from GitHub issue."""
        gh = action.github_issue
        local = action.local_issue

        _, title = IssueParser.extract_tag_from_title(gh.title)

        local.title = title
        local.content = gh.body
        local.labels = [
            l for l in gh.labels if l.upper() not in ["P0", "P1", "P2", "P3"]
        ]

        for label in gh.labels:
            if label.upper() in ["P0", "P1", "P2", "P3"]:
                local.priority = label.upper()
                break

        local.last_synced = datetime.now(timezone.utc).isoformat() + "Z"
        local.github_modified = gh.updated_at.isoformat()

        IssueParser.write_file(local, local.file_path)
        logger.info(f"  Updated: {local.file_path.relative_to(self.repo_root)}")

        self.state.issues[local.tag] = {
            **self.state.issues.get(local.tag, {}),
            "local_hash": IssueParser.compute_hash(local),
            "github_hash": self._compute_github_hash(gh),
            "last_synced": datetime.now(timezone.utc).isoformat() + "Z",
            "status": "synced",
        }

    def _update_github_issue(self, action: SyncAction):
        """Update GitHub issue from local file."""
        gh = action.github_issue
        local = action.local_issue

        title = IssueParser.format_github_title(local.tag, local.title)

        self.github.update_issue(number=gh.number, title=title, body=local.content)

        logger.info(f"  Updated GitHub issue #{gh.number}")

        self.state.issues[local.tag] = {
            **self.state.issues.get(local.tag, {}),
            "local_hash": IssueParser.compute_hash(local),
            "last_synced": datetime.now(timezone.utc).isoformat() + "Z",
            "status": "synced",
        }

    def _move_local_issue(self, action: SyncAction):
        """Move local issue to new status folder."""
        local = action.local_issue
        gh = action.github_issue

        new_status = self._map_github_status(gh.project_status)
        if new_status:
            new_path = IssueParser.move_issue(local, new_status, self.base_path)
            logger.info(f"  Moved to: {new_path.relative_to(self.repo_root)}")

            self.state.issues[local.tag] = {
                **self.state.issues.get(local.tag, {}),
                "local_path": str(new_path.relative_to(self.repo_root)),
                "last_synced": datetime.now(timezone.utc).isoformat() + "Z",
            }

    def _move_github_issue(self, action: SyncAction):
        """Update GitHub project status from local."""
        gh = action.github_issue
        local = action.local_issue

        if gh.project_item_id:
            gh_status = self._map_local_status(local.status)
            self.github.update_project_status(gh.project_item_id, gh_status)
            logger.info(f"  Updated GitHub status to: {gh_status}")

    def _handle_conflict(self, action: SyncAction):
        """Handle a sync conflict."""
        logger.warning(f"  CONFLICT: {action.details}")
        logger.warning(f"    Manual resolution required for {action.tag}")
        self.state.issues[action.tag] = {
            **self.state.issues.get(action.tag, {}),
            "status": "conflict",
            "conflict_at": datetime.now(timezone.utc).isoformat() + "Z",
        }

    def _import_untagged_issue(self, action: SyncAction):
        """Import an untagged GitHub issue."""
        gh = action.github_issue
        tag = action.tag

        original_title = gh.title
        clean_title = re.sub(r"^\[.*?\]\s*", "", original_title).strip()

        status = "backlog"
        priority = self.config.issues.default_priority
        for label in gh.labels:
            if label.upper() in ["P0", "P1", "P2", "P3"]:
                priority = label.upper()
                break

        body = gh.body or ""
        if len(body.strip()) < 100:
            body = f"""## Summary

{body if body.strip() else f"*{clean_title}*"}

## Problem Statement

<!-- Describe the problem this issue addresses -->

## Proposed Solution

<!-- Describe the proposed solution -->

## Acceptance Criteria

- [ ] Criteria 1
- [ ] Criteria 2

---

*Imported from GitHub issue #{gh.number}*
*Original title: {original_title}*
"""

        local = LocalIssue(
            tag=tag,
            title=clean_title,
            priority=priority,
            status=status,
            created=gh.created_at.strftime("%Y-%m-%d"),
            source="github",
            source_url=f"https://github.com/{self.github.owner}/{self.github.repo}/issues/{gh.number}",
            github_issue=gh.number,
            github_repo=f"{self.github.owner}/{self.github.repo}",
            labels=[l for l in gh.labels if l.upper() not in ["P0", "P1", "P2", "P3"]],
            assignees=gh.assignees,
            content=body,
            last_synced=datetime.now(timezone.utc).isoformat() + "Z",
        )

        folder = IssueParser.get_status_folder(status, self.base_path)
        filename = IssueParser.generate_filename(tag, clean_title)
        path = folder / filename

        IssueParser.write_file(local, path)
        logger.info(f"  Created local file: {path.relative_to(self.repo_root)}")

        new_title = IssueParser.format_github_title(tag, clean_title)
        try:
            self.github.update_issue(number=gh.number, title=new_title)
            logger.info(f"  Updated GitHub title: {new_title}")
        except GitHubClientError as e:
            logger.warning(f"  Could not update GitHub title: {e}")

        try:
            prefix, scope, _ = IssueParser.parse_tag(tag)
            labels_to_add = [prefix, scope, priority]
            self.github._ensure_labels_exist(labels_to_add)
            self.github.update_issue(number=gh.number, add_labels=labels_to_add)
            logger.info(f"  Added labels: {labels_to_add}")
        except (ValueError, GitHubClientError) as e:
            logger.warning(f"  Could not add labels: {e}")

        project_item_id = None
        if self.github.project_number:
            try:
                project_item_id = self.github.add_to_project(gh.number)
                gh_status = self._map_local_status(status)
                if project_item_id and gh_status:
                    self.github.update_project_status(project_item_id, gh_status)
                    logger.info(f"  Added to project with status: {gh_status}")

                if project_item_id and priority:
                    self.github.update_project_priority(project_item_id, priority)
                    logger.info(f"  Set project priority: {priority}")
            except GitHubClientError as e:
                logger.warning(f"  Could not add to project: {e}")

        self.state.issues[tag] = {
            "github_issue": gh.number,
            "github_project_item": project_item_id,
            "local_path": str(path.relative_to(self.repo_root)),
            "local_hash": IssueParser.compute_hash(local),
            "github_hash": self._compute_github_hash(gh),
            "last_synced": datetime.now(timezone.utc).isoformat() + "Z",
            "status": "synced",
            "imported_from": original_title,
        }

    def _add_issue_to_project(self, action: SyncAction):
        """Add an issue to the GitHub project board."""
        if not self.github.project_number:
            logger.warning("  No project configured, skipping")
            return

        gh = action.github_issue
        local = action.local_issue

        try:
            project_item_id = self.github.add_to_project(gh.number)

            if local:
                gh_status = self._map_local_status(local.status)
                if project_item_id and gh_status:
                    self.github.update_project_status(project_item_id, gh_status)
                    logger.info(f"  Set project status: {gh_status}")

                if project_item_id and local.priority:
                    self.github.update_project_priority(project_item_id, local.priority)
                    logger.info(f"  Set project priority: {local.priority}")

            if local and local.tag in self.state.issues:
                self.state.issues[local.tag]["github_project_item"] = project_item_id

            logger.info(f"  Added to project: {project_item_id}")

        except GitHubClientError as e:
            logger.warning(f"  Could not add to project: {e}")

    def _print_actions(self):
        """Print actions for dry run."""
        if self.config.sync.project_scoped:
            print(
                f"[project-scoped] Only processing issues in project #{self.config.github.project_number}"
            )

        if not self.actions:
            print("No changes detected.")
            return

        print("\nPlanned actions:")
        print("-" * 60)

        action_counts = {}
        for action in self.actions:
            action_type = action.action.value.upper()
            action_counts[action_type] = action_counts.get(action_type, 0) + 1
            print(f"[{action_type}] {action.tag}")
            print(f"    {action.details}")

        print("-" * 60)
        print("Summary:")
        for action_type, count in sorted(action_counts.items()):
            print(f"  {action_type}: {count}")
        print(f"  Total: {len(self.actions)}")

    def status(self):
        """Print sync status."""
        print(f"Sync State")
        print("=" * 40)
        print(f"Last sync: {self.state.last_sync or 'Never'}")
        print(
            f"Project: {self.state.project.get('owner')}/{self.state.project.get('repo')}"
        )
        print(f"Tracked issues: {len(self.state.issues)}")
        print(f"Tombstones: {len(self.state.tombstones)}")

        status_counts = {}
        for tag, info in self.state.issues.items():
            status = info.get("status", "unknown")
            status_counts[status] = status_counts.get(status, 0) + 1

        print("\nBy status:")
        for status, count in sorted(status_counts.items()):
            print(f"  {status}: {count}")


def main():
    """CLI entry point."""
    import argparse

    parser = argparse.ArgumentParser(description="GitHub Issues Sync Tool")
    subparsers = parser.add_subparsers(dest="command", help="Command to run")

    sync_parser = subparsers.add_parser("sync", help="Synchronize issues")
    sync_parser.add_argument(
        "--dry-run", "-n", action="store_true", help="Preview changes"
    )
    sync_parser.add_argument(
        "--direction",
        "-d",
        choices=["bidirectional", "github-to-local", "local-to-github"],
        default=None,
        help="Sync direction (default: from config.json sync.direction)",
    )
    sync_parser.add_argument(
        "--force", "-f", action="store_true", help="Override conflicts"
    )
    sync_parser.add_argument(
        "--verbose", "-v", action="store_true", help="Verbose output"
    )

    subparsers.add_parser("status", help="Show sync status")
    subparsers.add_parser("init", help="Initialize sync state")

    args = parser.parse_args()

    if args.command == "sync":
        if args.verbose:
            logging.getLogger().setLevel(logging.DEBUG)

        engine = SyncEngine()

        # CLI flag takes precedence, then config default, then "bidirectional"
        if args.direction:
            direction = SyncDirection(args.direction)
        else:
            config_direction = engine.config.sync.direction
            direction = SyncDirection(config_direction)
            logger.info(f"Using sync direction from config: {direction.value}")

        engine.sync(direction=direction, dry_run=args.dry_run, force=args.force)

    elif args.command == "status":
        engine = SyncEngine()
        engine.status()

    elif args.command == "init":
        engine = SyncEngine()
        engine._save_state()
        print("Initialized sync state")

    else:
        parser.print_help()


if __name__ == "__main__":
    main()
