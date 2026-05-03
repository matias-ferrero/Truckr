#!/usr/bin/env python3
"""
Issue Parser - Parse and write .issue.md files

This module handles reading and writing issue markdown files with YAML frontmatter.
Generalized version for the gdsi-sdlc plugin.
"""

import re
import yaml
import hashlib
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Tuple


@dataclass
class LocalIssue:
    """Represents an issue from a local .issue.md file."""

    # Required fields
    tag: str
    title: str
    priority: str
    status: str
    created: str

    # Source tracking
    source: str = "manual"
    source_url: str = ""
    author: str = ""

    # GitHub integration
    github_issue: Optional[int] = None
    github_project_item: Optional[str] = None
    github_repo: Optional[str] = None

    # Sync metadata
    last_synced: Optional[str] = None
    sync_hash: Optional[str] = None
    local_modified: Optional[str] = None
    github_modified: Optional[str] = None

    # Optional fields
    labels: List[str] = field(default_factory=list)
    assignees: List[str] = field(default_factory=list)
    milestone: Optional[str] = None
    pr_number: Optional[int] = None
    branch: Optional[str] = None

    # Content
    content: str = ""
    file_path: Optional[Path] = None

    # Preserve unknown frontmatter fields through the parse → write round-trip
    _extra_fields: Dict = field(default_factory=dict)

    def to_dict(self) -> Dict:
        """Convert to dictionary for YAML serialization."""
        data = {
            "tag": self.tag,
            "title": self.title,
            "priority": self.priority,
            "status": self.status,
            "created": self.created,
            "source": self.source,
            "source_url": self.source_url,
            "author": self.author,
        }

        # Add optional fields if present
        if self.github_issue:
            data["github_issue"] = self.github_issue
        if self.github_project_item:
            data["github_project_item"] = self.github_project_item
        if self.github_repo:
            data["github_repo"] = self.github_repo
        if self.last_synced:
            data["last_synced"] = self.last_synced
        if self.sync_hash:
            data["sync_hash"] = self.sync_hash
        if self.labels:
            data["labels"] = self.labels
        if self.assignees:
            data["assignees"] = self.assignees
        if self.milestone:
            data["milestone"] = self.milestone
        if self.pr_number:
            data["pr_number"] = self.pr_number
        if self.branch:
            data["branch"] = self.branch

        # Preserve any extra frontmatter fields from the original file
        if self._extra_fields:
            data.update(self._extra_fields)

        return data


class IssueParser:
    """Parse and write .issue.md files."""

    # Regex patterns
    # Scope allows 2-6 alphanumeric characters (e.g., AI, IO, API, CORE, ABBOTT, CLOUD)
    FRONTMATTER_PATTERN = re.compile(r"^---\n(.*?)\n---\n(.*)$", re.DOTALL)
    TAG_PATTERN = re.compile(r"^\[([A-Z]{3}-[A-Z0-9]{2,6}-[0-9X]{5})\]\s*(.+)$")
    TAG_VALIDATE_PATTERN = re.compile(r"^[A-Z]{3}-[A-Z0-9]{2,6}-[0-9]{5}$")
    UNASSIGNED_TAG_PATTERN = re.compile(r"^[A-Z]{3}-[A-Z0-9]{2,6}-X{5}$|^XXX-XXX-X{5}$")

    @classmethod
    def parse_file(cls, path: Path) -> LocalIssue:
        """Parse a .issue.md file into a LocalIssue object."""
        content = path.read_text(encoding="utf-8")
        match = cls.FRONTMATTER_PATTERN.match(content)

        if not match:
            raise ValueError(f"Invalid issue file format (no frontmatter): {path}")

        frontmatter_str, body = match.groups()

        try:
            frontmatter = yaml.safe_load(frontmatter_str)
        except yaml.YAMLError as e:
            raise ValueError(f"Invalid YAML frontmatter in {path}: {e}")

        if not frontmatter:
            frontmatter = {}

        known_keys = {
            "tag",
            "title",
            "priority",
            "status",
            "created",
            "source",
            "source_url",
            "author",
            "github_issue",
            "github_project_item",
            "github_repo",
            "last_synced",
            "sync_hash",
            "local_modified",
            "github_modified",
            "labels",
            "assignees",
            "milestone",
            "pr_number",
            "branch",
        }
        extra = {k: v for k, v in frontmatter.items() if k not in known_keys}

        return LocalIssue(
            tag=frontmatter.get("tag", ""),
            title=frontmatter.get("title", ""),
            priority=frontmatter.get("priority", "P2"),
            status=frontmatter.get("status", "backlog"),
            created=str(frontmatter.get("created", "")),
            source=frontmatter.get("source", "manual"),
            source_url=frontmatter.get("source_url", ""),
            author=frontmatter.get("author", ""),
            github_issue=frontmatter.get("github_issue"),
            github_project_item=frontmatter.get("github_project_item"),
            github_repo=frontmatter.get("github_repo"),
            last_synced=frontmatter.get("last_synced"),
            sync_hash=frontmatter.get("sync_hash"),
            labels=frontmatter.get("labels", []) or [],
            assignees=frontmatter.get("assignees", []) or [],
            milestone=frontmatter.get("milestone"),
            pr_number=frontmatter.get("pr_number"),
            branch=frontmatter.get("branch"),
            content=body.strip(),
            file_path=path,
            _extra_fields=extra,
        )

    @classmethod
    def write_file(cls, issue: LocalIssue, path: Path) -> None:
        """Write a LocalIssue to a .issue.md file."""
        frontmatter = issue.to_dict()

        # Format YAML with consistent style
        yaml_content = yaml.dump(
            frontmatter, default_flow_style=False, allow_unicode=True, sort_keys=False
        )

        content = f"---\n{yaml_content}---\n\n{issue.content}\n"

        # Ensure parent directory exists
        path.parent.mkdir(parents=True, exist_ok=True)

        path.write_text(content, encoding="utf-8")
        issue.file_path = path

    @classmethod
    def extract_tag_from_title(cls, title: str) -> Tuple[Optional[str], str]:
        """
        Extract TAG from GitHub issue title format: [TAG] Title

        Returns:
            Tuple of (tag, remaining_title). Tag is None if not found.
        """
        match = cls.TAG_PATTERN.match(title.strip())
        if match:
            return match.group(1), match.group(2).strip()
        return None, title.strip()

    @classmethod
    def format_github_title(cls, tag: str, title: str) -> str:
        """Format title for GitHub: [TAG] Title"""
        return f"[{tag}] {title}"

    @classmethod
    def is_valid_tag(cls, tag: str) -> bool:
        """Check if a tag follows the valid format."""
        return bool(cls.TAG_VALIDATE_PATTERN.match(tag))

    @classmethod
    def is_unassigned_tag(cls, tag: str) -> bool:
        """Check if a tag is an unassigned placeholder."""
        return bool(cls.UNASSIGNED_TAG_PATTERN.match(tag))

    @classmethod
    def parse_tag(cls, tag: str) -> Tuple[str, str, str]:
        """
        Parse a tag into its components.

        Returns:
            Tuple of (prefix, scope, number)
        """
        parts = tag.split("-")
        if len(parts) != 3:
            raise ValueError(f"Invalid tag format: {tag}")
        return parts[0], parts[1], parts[2]

    @classmethod
    def compute_hash(cls, issue: LocalIssue) -> str:
        """Compute content hash for change detection."""
        content = f"{issue.title}|{issue.priority}|{issue.status}|{issue.content}"
        return hashlib.sha256(content.encode()).hexdigest()[:16]

    @classmethod
    def scan_folder(
        cls, folder: Path, include_archived: bool = False
    ) -> List[LocalIssue]:
        """
        Scan a folder for .issue.md files.

        Args:
            folder: Directory to scan
            include_archived: Include .archived.md and .deleted.md files

        Returns:
            List of LocalIssue objects
        """
        issues = []

        if not folder.exists():
            return issues

        for path in folder.glob("*.issue.md"):
            # Skip tombstoned files unless requested
            if not include_archived:
                if path.stem.endswith(".archived") or path.stem.endswith(".deleted"):
                    continue

            try:
                issues.append(cls.parse_file(path))
            except Exception as e:
                print(f"Warning: Could not parse {path}: {e}")

        return issues

    @classmethod
    def scan_all_folders(
        cls, base_path: Path, folders: List[str] = None
    ) -> Dict[str, LocalIssue]:
        """
        Scan all status folders and return issues indexed by TAG.

        Args:
            base_path: Base path containing status folders
            folders: List of folder names to scan (default: all status folders)

        Returns:
            Dict mapping TAG to LocalIssue
        """
        if folders is None:
            folders = ["Backlog", "Ready", "InProgress", "InReview", "Done"]

        result = {}

        for folder in folders:
            folder_path = base_path / folder
            folder_status = cls.get_status_from_folder(folder)
            for issue in cls.scan_folder(folder_path):
                if issue.tag:
                    if issue.status.lower() != folder_status:
                        issue.status = folder_status
                    result[issue.tag] = issue

        return result

    @classmethod
    def get_status_folder(cls, status: str, base_path: Path) -> Path:
        """Map status to folder path."""
        status_map = {
            "backlog": "Backlog",
            "ready": "Ready",
            "in_progress": "InProgress",
            "in_review": "InReview",
            "done": "Done",
        }
        folder_name = status_map.get(status.lower(), "Backlog")
        return base_path / folder_name

    @classmethod
    def get_status_from_folder(cls, folder_name: str) -> str:
        """Map folder name to status."""
        folder_map = {
            "Backlog": "backlog",
            "Ready": "ready",
            "InProgress": "in_progress",
            "InReview": "in_review",
            "Done": "done",
        }
        return folder_map.get(folder_name, "backlog")

    @classmethod
    def slugify(cls, text: str, max_length: int = 50) -> str:
        """Convert text to URL-friendly slug."""
        text = text.lower()
        text = re.sub(r"[^\w\s-]", "", text)
        text = re.sub(r"[\s_]+", "-", text)
        text = text.strip("-")
        return text[:max_length]

    @classmethod
    def generate_filename(cls, tag: str, title: str) -> str:
        """Generate a filename from tag and title."""
        slug = cls.slugify(title)
        return f"{tag}-{slug}.issue.md"

    @classmethod
    def move_issue(cls, issue: LocalIssue, new_status: str, base_path: Path) -> Path:
        """
        Move an issue file to a new status folder and update the status in the file.

        Args:
            issue: The issue to move
            new_status: The new status
            base_path: Base path containing status folders

        Returns:
            New file path
        """
        if not issue.file_path:
            raise ValueError("Issue has no file path")

        new_folder = cls.get_status_folder(new_status, base_path)
        new_folder.mkdir(parents=True, exist_ok=True)
        new_path = new_folder / issue.file_path.name

        issue.file_path.rename(new_path)
        issue.status = new_status
        issue.file_path = new_path
        cls.write_file(issue, new_path)

        return new_path

    @classmethod
    def archive_issue(cls, issue: LocalIssue, reason: str = "archived") -> Path:
        """
        Archive an issue by renaming with .archived suffix.

        Args:
            issue: The issue to archive
            reason: Reason for archiving

        Returns:
            New file path
        """
        if not issue.file_path:
            raise ValueError("Issue has no file path")

        stem = issue.file_path.stem
        if not stem.endswith(".archived"):
            new_name = f"{stem}.archived.md"
        else:
            new_name = issue.file_path.name

        new_path = issue.file_path.parent / new_name
        issue.status = "archived"
        issue.content = f"[ARCHIVED] {reason}\n\n{issue.content}"

        if issue.file_path != new_path:
            issue.file_path.rename(new_path)

        cls.write_file(issue, new_path)
        issue.file_path = new_path

        return new_path


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1:
        path = Path(sys.argv[1])
        issue = IssueParser.parse_file(path)
        print(f"Tag: {issue.tag}")
        print(f"Title: {issue.title}")
        print(f"Priority: {issue.priority}")
        print(f"Status: {issue.status}")
        print(f"Hash: {IssueParser.compute_hash(issue)}")
    else:
        print("Usage: python issue_parser.py <path-to-issue.md>")
