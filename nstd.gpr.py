#!/usr/bin/env python3
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

class std(BuilderApp):
    project_file = os.path.join(SOURCE_DIR, "nstd.gpr")
    description = "Non-Standard Runtime Experiments"
    constants_project_file = os.path.join(SOURCE_DIR, "config", "nstd_config.gpr")
    constants = ["NSTD_XXHASH_ARCH"]

    def add_arguments(self, parser: argparse.ArgumentParser) -> None:
        parser.add_argument("--build", choices=["DEBUG", "PROD"], default="PROD")
        parser.add_argument("--enable-shared", choices=["yes", "no"], default="yes")
        parser.add_argument("--finalization", choices=["standard", "relaxed", "auto"], default="auto")
        parser.add_argument("--ref-counting", choices=["rc", "arc", "biased"], default="arc")
        parser.add_argument("--malloc", choices=["mimalloc", "malloc"], default="malloc")

    def adjust_config(self, gpr: GPRTool, args: argparse.Namespace) -> None:
        with open(os.path.join(SOURCE_DIR, "VERSION")) as fd:
            version = fd.read().strip()
        gpr.set_variable("NSTD_VERSION", version)

        if "windows" in gpr.target:
            gnatcoll_os = "windows"
        elif "darwin" in gpr.target:
            gnatcoll_os = "osx"
        else:
            gnatcoll_os = "unix"
        gpr.set_variable("NSTD_OS", gnatcoll_os)
        gpr.set_variable("NSTD_BUILD_MODE", args.build)

        if args.finalization == "auto":
            # Ideally detect if compiler support the new scheme
            args.finalization = "relaxed"

        gpr.set_variable("NSTD_FINALIZATION", args.finalization)
        gpr.set_variable("NSTD_REFCOUNT", args.ref_counting)
        gpr.set_variable("NSTD_MALLOC", args.malloc)

        # Compute which implementation should be used for xxhash
        if gpr.target in ("x86_64-linux", "x86_64-windows"):
            xxhash_arch = "x86_64"
        else:
            xxhash_arch = "generic"

        logging.debug(f"xxhash implementation: {xxhash_arch}")
        gpr.set_variable("NSTD_XXHASH_ARCH", xxhash_arch)

        if args.gnatcov:
            gpr.set_variable("LIBRARY_TYPE", "static")
        else:
            gpr.variants_var = "LIBRARY_TYPE"
            if args.enable_shared == "yes":
                gpr.variants_values = ["static", "relocatable", "static-pic"]
            else:
                gpr.variants_values = ["static"]

if __name__ == "__main__":
    app = std()
    sys.exit(app.run())
