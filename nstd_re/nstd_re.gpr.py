#!/usr/bin/env python
from __future__ import annotations
from typing import TYPE_CHECKING
import logging
import sys
import os

# Support code is located in parent directory
SOURCE_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.append(os.path.dirname(SOURCE_DIR))

from gprproject import BuilderApp

if TYPE_CHECKING:
    import argparse
    from gprproject.gprbuild import GPRTool

class NStd_Re(BuilderApp):
    project_file = os.path.join(SOURCE_DIR, "nstd_re.gpr")
    description = "This is the project description"
    constants_project_file = os.path.join(SOURCE_DIR, "config", "nstd_re_config.gpr")

    def add_arguments(self, parser: argparse.ArgumentParser) -> None:
        parser.add_argument("--build", choices=["DEBUG", "PROD"], default="PROD")
        parser.add_argument("--enable-shared", choices=["yes", "no"], default="yes")

    def adjust_config(self, gpr: GPRTool, args: argparse.Namespace) -> None:
        with open(os.path.join(SOURCE_DIR, "VERSION")) as fd:
            version = fd.read().strip()
        gpr.set_variable("NSTD_RE_VERSION", version)

        if "windows" in gpr.target:
            gnatcoll_os = "windows"
        elif "darwin" in gpr.target:
            gnatcoll_os = "osx"
        else:
            gnatcoll_os = "unix"
        gpr.set_variable("NSTD_RE_OS", gnatcoll_os)
        gpr.set_variable("NSTD_RE_BUILD_MODE", args.build)

        if args.gnatcov:
            gpr.set_variable("LIBRARY_TYPE", "static")
        else:
            gpr.variants_var = "LIBRARY_TYPE"
            if args.enable_shared == "yes":
                gpr.variants_values = ["static", "relocatable", "static-pic"]
            else:
                gpr.variants_values = ["static"]

if __name__ == "__main__":
    app = NStd_Re()
    sys.exit(app.run())
