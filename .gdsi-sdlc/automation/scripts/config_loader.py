#!/usr/bin/env python3
"""
Configuration Loader

Loads and validates the gdsi-sdlc configuration from .gdsi-sdlc/config.json
"""

import json
import subprocess
from pathlib import Path
from typing import Dict, Optional, List
from dataclasses import dataclass, field


@dataclass
class GitHubConfig:
    """GitHub configuration."""

    owner: str
    repo: str
    project_number: Optional[int] = None
    owner_type: Optional[str] = None  # 'user', 'org', or None for auto-detect

    @property
    def repository(self) -> str:
        return f"{self.owner}/{self.repo}"


@dataclass
class PathsConfig:
    """Paths configuration."""

    issues_base: str
    features: str
    automation: str = ".gdsi-sdlc/automation"
    sessions: str = ".gdsi-sdlc/sessions"


@dataclass
class IssueConfig:
    """Issue configuration."""

    prefixes: List[str] = field(
        default_factory=lambda: ["REQ", "FIX", "DOC", "TST", "REF", "INF", "REL"]
    )
    scopes: List[str] = field(default_factory=list)
    default_scope: str = "GEN"
    default_prefix: str = "REQ"
    default_priority: str = "P2"

    # Validation constants
    MIN_SCOPE_LENGTH = 2
    MAX_SCOPE_LENGTH = 6
    PREFIX_LENGTH = 3

    def validate(self) -> List[str]:
        """Validate issue configuration. Returns list of error messages."""
        errors = []

        # Validate prefixes (must be exactly 3 uppercase letters)
        for prefix in self.prefixes:
            if (
                len(prefix) != self.PREFIX_LENGTH
                or not prefix.isalpha()
                or not prefix.isupper()
            ):
                errors.append(
                    f"Invalid prefix '{prefix}': must be exactly {self.PREFIX_LENGTH} uppercase letters"
                )

        # Validate scopes (must be 2-6 uppercase alphanumeric characters)
        for scope in self.scopes:
            if len(scope) < self.MIN_SCOPE_LENGTH or len(scope) > self.MAX_SCOPE_LENGTH:
                errors.append(
                    f"Invalid scope '{scope}': must be {self.MIN_SCOPE_LENGTH}-{self.MAX_SCOPE_LENGTH} characters, "
                    f"got {len(scope)}"
                )
            elif not scope.isalnum() or not scope.isupper():
                errors.append(
                    f"Invalid scope '{scope}': must be uppercase alphanumeric"
                )

        # Validate default_scope
        if (
            len(self.default_scope) < self.MIN_SCOPE_LENGTH
            or len(self.default_scope) > self.MAX_SCOPE_LENGTH
        ):
            errors.append(
                f"Invalid default_scope '{self.default_scope}': must be {self.MIN_SCOPE_LENGTH}-{self.MAX_SCOPE_LENGTH} characters"
            )

        # Validate default_prefix
        if len(self.default_prefix) != self.PREFIX_LENGTH:
            errors.append(
                f"Invalid default_prefix '{self.default_prefix}': must be {self.PREFIX_LENGTH} characters"
            )

        # Validate default_prefix is in the prefixes list
        if self.default_prefix not in self.prefixes:
            errors.append(
                f"default_prefix '{self.default_prefix}' is not in configured prefixes: {self.prefixes}"
            )

        # Validate default_scope is in the scopes list (if scopes are configured)
        if self.scopes and self.default_scope not in self.scopes:
            errors.append(
                f"default_scope '{self.default_scope}' is not in configured scopes: {self.scopes}"
            )

        # Validate default_priority format
        valid_priorities = {"P0", "P1", "P2", "P3"}
        if self.default_priority not in valid_priorities:
            errors.append(
                f"default_priority '{self.default_priority}' must be one of: {sorted(valid_priorities)}"
            )

        return errors


@dataclass
class SyncConfig:
    """Sync configuration."""

    direction: str = "bidirectional"  # bidirectional, github-to-local, local-to-github
    conflict_strategy: str = "flag"  # flag, github-wins, local-wins
    project_scoped: bool = True  # Only sync issues belonging to the configured project


@dataclass
class VcsConfig:
    """Version control configuration."""

    branch_prefix: str = "feature"
    branch_pattern: str = "{prefix}/{tag}-{slug}"
    slug_max_length: int = 40

    def format_branch_name(self, tag: str, title: str) -> str:
        """Generate a branch name from TAG and title."""
        import re

        slug = re.sub(r"[^a-z0-9]", "-", title.lower())
        slug = re.sub(r"-{2,}", "-", slug).strip("-")
        slug = slug[: self.slug_max_length]
        return self.branch_pattern.format(prefix=self.branch_prefix, tag=tag, slug=slug)


@dataclass
class AutomationConfig:
    """Automation configuration."""

    enabled: bool = False
    max_concurrent: int = 3
    cooldowns: Dict[str, int] = field(
        default_factory=lambda: {
            "after_plan": 60,
            "after_implement": 120,
            "after_troubleshoot": 30,
            "after_review": 60,
        }
    )


@dataclass
class gdsiSdlcConfig:
    """Main configuration class."""

    version: str
    github: GitHubConfig
    paths: PathsConfig
    issues: IssueConfig
    sync: SyncConfig
    automation: AutomationConfig
    vcs: VcsConfig = field(default_factory=VcsConfig)

    # Status folder mappings
    status_mapping: Dict[str, str] = field(
        default_factory=lambda: {
            "Backlog": "Backlog",
            "Ready": "Ready",
            "In progress": "InProgress",
            "In review": "InReview",
            "Done": "Done",
        }
    )

    folder_to_status: Dict[str, str] = field(
        default_factory=lambda: {
            "Backlog": "Backlog",
            "Ready": "Ready",
            "InProgress": "In progress",
            "InReview": "In review",
            "Done": "Done",
        }
    )


class ConfigLoader:
    """Loads and validates gdsi-sdlc configuration."""

    CONFIG_FILE = ".gdsi-sdlc/config.json"

    def __init__(self, repo_root: Optional[Path] = None):
        """
        Initialize the configuration loader.

        Args:
            repo_root: Repository root path (auto-detected if None)
        """
        self.repo_root = repo_root or self._find_repo_root()
        self.config_path = self.repo_root / self.CONFIG_FILE
        self._config: Optional[gdsiSdlcConfig] = None

    def _find_repo_root(self) -> Path:
        """Find the git repository root."""
        try:
            result = subprocess.run(
                ["git", "rev-parse", "--show-toplevel"], capture_output=True, text=True
            )
            if result.returncode == 0:
                return Path(result.stdout.strip())
        except FileNotFoundError:
            pass

        # Fall back to walking up directories
        current = Path.cwd()
        while current != current.parent:
            if (current / ".git").exists():
                return current
            current = current.parent

        return Path.cwd()

    def exists(self) -> bool:
        """Check if configuration file exists."""
        return self.config_path.exists()

    def load(self) -> gdsiSdlcConfig:
        """Load configuration from file."""
        if self._config:
            return self._config

        if not self.exists():
            raise FileNotFoundError(
                f"Configuration file not found: {self.config_path}\n"
                "Run '/gdsi-sdlc:init' to initialize the project."
            )

        data = json.loads(self.config_path.read_text())

        # Parse nested configurations
        # Support both formats: separate owner/repo OR combined repository
        github_data = data["github"]
        if "repository" in github_data and "owner" not in github_data:
            # Parse "owner/repo" format (legacy)
            parts = github_data["repository"].split("/", 1)
            owner = parts[0]
            repo = parts[1] if len(parts) > 1 else parts[0]
        else:
            owner = github_data["owner"]
            repo = github_data["repo"]

        github = GitHubConfig(
            owner=owner,
            repo=repo,
            project_number=github_data.get("project_number"),
            owner_type=github_data.get("owner_type", "user"),
        )

        paths = PathsConfig(
            issues_base=data["paths"]["issues_base"],
            features=data["paths"]["features"],
            automation=data["paths"].get("automation", ".gdsi-sdlc/automation"),
            sessions=data["paths"].get("sessions", ".gdsi-sdlc/sessions"),
        )

        issues_data = data.get("issues", {})
        issues = IssueConfig(
            prefixes=issues_data.get(
                "prefixes", ["REQ", "FIX", "DOC", "TST", "REF", "INF", "REL"]
            ),
            scopes=issues_data.get("scopes", []),
            default_scope=issues_data.get("default_scope", "GEN"),
            default_prefix=issues_data.get("default_prefix", "REQ"),
            default_priority=issues_data.get("default_priority", "P2"),
        )

        sync_data = data.get("sync", {})
        sync = SyncConfig(
            direction=sync_data.get("direction", "bidirectional"),
            conflict_strategy=sync_data.get("conflict_strategy", "flag"),
            project_scoped=sync_data.get("project_scoped", True),
        )

        automation_data = data.get("automation", {})
        cooldowns = automation_data.get("cooldowns", {})
        # Normalize cooldown key names: support both "plan_minutes" and "after_plan" formats
        normalized_cooldowns = {}
        for key, value in cooldowns.items():
            normalized_key = key.replace("_minutes", "").replace("after_", "")
            normalized_cooldowns[f"after_{normalized_key}"] = value
        if not normalized_cooldowns:
            normalized_cooldowns = {
                "after_plan": 60,
                "after_implement": 120,
                "after_troubleshoot": 30,
                "after_review": 60,
            }

        automation = AutomationConfig(
            enabled=automation_data.get("enabled", False),
            max_concurrent=automation_data.get("max_concurrent", 3),
            cooldowns=normalized_cooldowns,
        )

        vcs_data = data.get("vcs", {})
        vcs = VcsConfig(
            branch_prefix=vcs_data.get("branch_prefix", "feature"),
            branch_pattern=vcs_data.get("branch_pattern", "{prefix}/{tag}-{slug}"),
            slug_max_length=vcs_data.get("slug_max_length", 40),
        )

        self._config = gdsiSdlcConfig(
            version=data.get("version", "1.0.0"),
            github=github,
            paths=paths,
            issues=issues,
            sync=sync,
            automation=automation,
            vcs=vcs,
            status_mapping=data.get("status_mapping", {}),
            folder_to_status=data.get("folder_to_status", {}),
        )

        # Validate configuration
        self._validate_config(self._config)

        return self._config

    def _validate_config(self, config: gdsiSdlcConfig) -> None:
        """Validate the loaded configuration."""
        errors = []

        # Validate issues configuration
        issue_errors = config.issues.validate()
        errors.extend(issue_errors)

        # Validate sync config
        valid_directions = {"bidirectional", "github-to-local", "local-to-github"}
        if config.sync.direction not in valid_directions:
            errors.append(
                f"sync.direction '{config.sync.direction}' must be one of: {sorted(valid_directions)}"
            )

        valid_strategies = {"flag", "github-wins", "local-wins"}
        if config.sync.conflict_strategy not in valid_strategies:
            errors.append(
                f"sync.conflict_strategy '{config.sync.conflict_strategy}' must be one of: {sorted(valid_strategies)}"
            )

        # Validate status mappings are bidirectional
        for gh_status, local_folder in config.status_mapping.items():
            reverse = config.folder_to_status.get(local_folder)
            if reverse != gh_status:
                errors.append(
                    f"Status mapping inconsistency: '{gh_status}' -> '{local_folder}' "
                    f"but reverse maps to '{reverse}'"
                )

        if errors:
            error_msg = "Configuration validation failed:\n" + "\n".join(
                f"  - {e}" for e in errors
            )
            raise ValueError(error_msg)

    def save(self, config: gdsiSdlcConfig):
        """Save configuration to file."""
        data = {
            "version": config.version,
            "github": {
                "owner": config.github.owner,
                "repo": config.github.repo,
                "project_number": config.github.project_number,
                "owner_type": config.github.owner_type,
            },
            "paths": {
                "issues_base": config.paths.issues_base,
                "features": config.paths.features,
                "automation": config.paths.automation,
                "sessions": config.paths.sessions,
            },
            "issues": {
                "prefixes": config.issues.prefixes,
                "scopes": config.issues.scopes,
                "default_scope": config.issues.default_scope,
                "default_prefix": config.issues.default_prefix,
                "default_priority": config.issues.default_priority,
            },
            "sync": {
                "direction": config.sync.direction,
                "conflict_strategy": config.sync.conflict_strategy,
                "project_scoped": config.sync.project_scoped,
            },
            "automation": {
                "enabled": config.automation.enabled,
                "max_concurrent": config.automation.max_concurrent,
                "cooldowns": config.automation.cooldowns,
            },
            "vcs": {
                "branch_prefix": config.vcs.branch_prefix,
                "branch_pattern": config.vcs.branch_pattern,
                "slug_max_length": config.vcs.slug_max_length,
            },
            "status_mapping": config.status_mapping,
            "folder_to_status": config.folder_to_status,
        }

        self.config_path.parent.mkdir(parents=True, exist_ok=True)
        self.config_path.write_text(json.dumps(data, indent=2))
        self._config = config

    def get_issues_base_path(self) -> Path:
        """Get the absolute path to the issues base directory."""
        config = self.load()
        return self.repo_root / config.paths.issues_base

    def get_features_path(self) -> Path:
        """Get the absolute path to the features directory."""
        config = self.load()
        return self.repo_root / config.paths.features

    def get_automation_path(self) -> Path:
        """Get the absolute path to the automation directory."""
        config = self.load()
        return self.repo_root / config.paths.automation

    def get_sessions_path(self) -> Path:
        """Get the absolute path to the sessions directory."""
        config = self.load()
        return self.repo_root / config.paths.sessions


def get_config(repo_root: Optional[Path] = None) -> gdsiSdlcConfig:
    """Convenience function to load configuration."""
    loader = ConfigLoader(repo_root)
    return loader.load()


if __name__ == "__main__":
    # Test configuration loading
    import sys

    try:
        loader = ConfigLoader()
        if loader.exists():
            config = loader.load()
            print(f"Configuration loaded:")
            print(f"  Version: {config.version}")
            print(f"  Repository: {config.github.repository}")
            print(f"  Issues base: {config.paths.issues_base}")
            print(f"  Features: {config.paths.features}")
            print(f"  Automation enabled: {config.automation.enabled}")
        else:
            print("Configuration not found. Run '/gdsi-sdlc:init' to initialize.")
            sys.exit(1)
    except Exception as e:
        print(f"Error: {e}")
        sys.exit(1)
