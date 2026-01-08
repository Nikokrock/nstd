import sys
import os
import re
from subprocess import run


class VersionError(Exception):
    pass


class VersionElement:
    """Version element (major, minor or patch)"""

    def __init__(self, spec: str) -> None:
        """Initialize a version element.

        :param spec: an element spec should have the following form:
            <BASE_NUMBER>[+breaking][+feature][+fix]. The BASE_NUMBER
            is the starting point of the version element. It can be incremented
            by counting optionally the number of breaking changes, features or
            fixes.
        """
        # Starting value
        self.value = 0

        # Which counter should be enabled for that element
        self.counters = {"breaking": False, "feature": False, "fix": False}
        self.is_constant = True

        for arg in spec.split("+"):
            m = re.match(r"([0-9]+)|(breaking|feature|fix)$", arg)
            if m:
                if m.group(1):
                    # This is a number. Bump version accordingly
                    self.value += int(m.group(1))

                elif m.group(2):
                    # This is a counter to enable
                    self.counters[m.group(2)] = True
                    self.is_constant = False
            else:
                raise VersionError(f"invalid version specification: {spec}")

    def increment(self, key: str) -> bool:
        """Handle the increment of a counter

        :param key: the counter name (breaking, feature or fix)
        :return: True if the element has been incremented
        """
        if self.counters[key]:
            self.value += 1
            return True
        else:
            return False

    def reset(self):
        """Reset element value to 0"""
        self.value = 0


class Version:
    """Version specification."""

    def __init__(self, version: str) -> None:
        major_spec, minor_spec, patch_spec = (el for el in version.split("."))
        self.major = VersionElement(major_spec)
        self.minor = VersionElement(minor_spec)
        self.patch = VersionElement(patch_spec)

    def is_constant(self) -> bool:
        return (
            self.major.is_constant and self.minor.is_constant and self.path.is_constant
        )

    def add_fix(self):
        if self.major.increment("fix"):
            self.minor.reset()
            self.patch.reset()
        elif self.minor.increment("fix"):
            self.patch.reset()
        else:
            self.patch.increment("fix")

    def add_feature(self):
        if self.major.increment("feature"):
            self.minor.reset()
            self.patch.reset()
        elif self.minor.increment("feature"):
            self.patch.reset()
        else:
            self.patch.increment("feature")

    def add_breaking_change(self):
        if self.major.increment("breaking"):
            self.minor.reset()
            self.patch.reset()
        elif self.minor.increment("breaking"):
            self.patch.reset()
        else:
            self.patch.increment("breaking")

    def __str__(self):
        return f"{self.major.value}.{self.minor.value}.{self.patch.value}"


def get_current_version(version_file: str) -> str:
    version_file = os.path.abspath(version_file)
    project_dir = os.path.dirname(version_file)
    assert os.path.isfile(version_file)

    with open(version_file) as fd:
        version = Version(fd.read().strip())

    p = run(
        ["git", "log", "-n", "1", "--pretty=oneline", os.path.basename(version_file)],
        cwd=project_dir,
        capture_output=True,
        check=True,
    )
    ver_file_commit = p.stdout.split(b" ", 1)[0].decode("utf-8")

    p = run(
        [
            "git",
            "log",
            "--reverse",
            "--format=%(trailers:separator=|,key=Kind,valueonly)",
            f"{ver_file_commit}..HEAD",
            ".",
        ],
        cwd=project_dir,
        capture_output=True,
        check=True,
    )
    commits = p.stdout.decode("utf-8").splitlines()
    for c in commits:
        kinds = [el.strip() for el in c.split(",")]
        if "breaking change" in kinds:
            version.add_breaking_change()
        elif "feature" in kinds:
            version.add_feature()
        elif "fix" in kinds:
            version.add_fix()
    return str(version)
