from __future__ import annotations
from e3.fs import mkdir
from e3.main import Main
import os
import sys

CONFIG_PROJECT_TEMPLATE = """
abstract project {self.project_name}_Constants is
    {self.variable_prefix}_VERSION_DEFAULT := "0.0";
    {self.variable_prefix}_OS_DEFAULT := "unix";
    {self.variable_prefix}_BUILD_MODE_DEFAULT := "PROD";
end {self.project_name}_Constants;
"""

BUILD_SCRIPT_TEMPLATE = """
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

class {self.project_name}(BuilderApp):
    project_file = os.path.join(SOURCE_DIR, "{self.project_path_name}.gpr")
    description = "This is the project description"
    constants_project_file = os.path.join(SOURCE_DIR, "config", "{self.project_path_name}_config.gpr")

    def add_arguments(self, parser: argparse.ArgumentParser) -> None:
        parser.add_argument("--build", choices=["DEBUG", "PROD"], default="PROD")
        parser.add_argument("--enable-shared", choices=["yes", "no"], default="yes")

    def adjust_config(self, gpr: GPRTool, args: argparse.Namespace) -> None:
        with open(os.path.join(SOURCE_DIR, "VERSION")) as fd:
            version = fd.read().strip()
        gpr.set_variable("{self.variable_prefix}_VERSION", version)

        if "windows" in gpr.target:
            gnatcoll_os = "windows"
        elif "darwin" in gpr.target:
            gnatcoll_os = "osx"
        else:
            gnatcoll_os = "unix"
        gpr.set_variable("{self.variable_prefix}_OS", gnatcoll_os)
        gpr.set_variable("{self.variable_prefix}_BUILD_MODE", args.build)

        if args.gnatcov:
            gpr.set_variable("LIBRARY_TYPE", "static")
        else:
            gpr.variants_var = "LIBRARY_TYPE"
            if args.enable_shared == "yes":
                gpr.variants_values = ["static", "relocatable", "static-pic"]
            else:
                gpr.variants_values = ["static"]

if __name__ == "__main__":
    app = {self.project_name}()
    sys.exit(app.run())
"""

PROJECT_TEMPLATE = """
with "config/{self.project_path_name}_constants.gpr";

library project {self.project_name} is
   --  Version handling is managed by the build script that use the VERSION
   --  file as reference for the library version
   --  (used only when building a shared library)
   Version := External(
      "{self.variable_prefix}_VERSION",
      {self.project_name}_Constants.{self.variable_prefix}_VERSION_DEFAULT);

   --  Get the current OS type. The value is used to compute the expected
   --  shared library extension. The user can use this value to have system
   --  specific configurations (for example in Naming package).
   --  (used only when building a shared library)
   type OS_Kind is ("windows", "unix", "osx");
   OS : OS_Kind := External
      ("{self.variable_prefix}_OS",
      {self.project_name}_Constants.{self.variable_prefix}_OS_DEFAULT);

   --  Used to select a DEBUG or PROD build
   type Build_Type is ("DEBUG", "PROD");
   Build : Build_Type := External
      ("{self.variable_prefix}_BUILD_MODE",
      External
         ("BUILD",
          {self.project_name}_Constants.{self.variable_prefix}_BUILD_MODE_DEFAULT));

   --  Kind of library to be built
   type Library_Types is ("relocatable", "static", "static-pic");
   Library_Type : Library_Types := External ("LIBRARY_TYPE", "static");

   Project_Languages := ({self.languages_str});
   Sources := ("src");

   for Languages use Project_Languages;

    for Source_Dirs use Sources;
    --  If the library is built out of tree, and is used by an external
    --  afterwards, then {self.variable_prefix}_OBJECT_ROOT can be used so
    --  {self.project_path_name}.gpr Object_Dir and Library_Dir point to
    --  the correct directory.
    Object_Root := external ("{self.variable_prefix}_OBJECT_ROOT", "");

    case OS is
       when "windows" | "osx" =>
          --  On MacOS and Windows all object are relocatable by default
          --  thus the same object directory can be used
          for Object_Dir use Object_Root & "obj/{self.project_path_name}/all";
       when "unix" =>
          --  On Unix static-pic and relocatable shared the same objects
          case Library_Type is
             when "relocatable" | "static-pic" =>
                for Object_Dir use Object_Root & "obj/{self.project_path_name}/pic";
             when "static" =>
                for Object_Dir use Object_Root & "obj/{self.project_path_name}/static";
          end case;
    end case;

    for Library_Name use "{self.project_path_name}";
    for Library_Kind use Library_Type;
    for Library_Dir
        use Object_Root & "lib/{self.project_path_name}/" & Project'Library_Kind;
    package Ide is
        for VCS_Kind use "Git";
    end Ide;

    So_Ext := "";
    case OS is
        when "windows" =>
           So_Ext := ".dll";
        when "osx" =>
           So_Ext := ".dylib";
        when others =>
           So_Ext := ".so";
    end case;

    for Library_Version use "lib" & Project'Library_Name & So_Ext & "." & Version;

    package Compiler is
       case Build is
          when "DEBUG" =>
             for Switches ("Ada") use (
                 --  Standard debugging flags (debug info and no optimisation)
                 "-g", "-O0",
                 --  Enable pragma Assert and Debug
                 "-gnata",
                 --  Turn on all the validity checks
                 "-gnatVa",
                 --  Write ali/tree file even if compile errors
                 "-gnatQ",
                 --  Enable default style checks
                 "-gnaty",
                 --  Add extra information in exception messages
                 "-gnateE",
                 --  Activate default warnings and mark all warnings as error
                 "-gnatwae",
                 --  Activate stack checking
                 "-fstack-check");
             for Switches ("C") use ("-g", "-O0", "-Wunreachable-code");

          when "PROD" =>
             --  Enable optimisation and inlining. Do not treat warnings as errors
             for Switches ("Ada") use ("-O2", "-gnatn", "-gnatwa");
             for Switches ("C") use ("-O2", "-Wunreachable-code");
       end case;
    end Compiler;

    package Binder is
       case Build is
          when "DEBUG" =>
             --  For symbolic bactrace
             for Switches ("Ada") use ("-E");
          when "PROD" =>
             null;
       end case;
   end Binder;
end {self.project_name};
"""

TESTSUITE_SCRIPT = """#!/usr/bin/env python3
from __future__ import annotations
import sys
import os

ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.dirname(os.path.dirname(ROOT_DIR)))

from gprproject.testsuite import LibTestsuite

class {self.project_path_name}Testsuite(LibTestsuite):
    @property
    def default_withed_projects(self) -> list[str]:
        return ["{self.project_path_name}"]

if __name__ == '__main__':
    {self.project_path_name}Testsuite.main(os.path.dirname(__file__))
"""


class AdaLibProject:
    def __init__(self, target_dir, project_name, languages):
        self.project_name = project_name
        self.target_dir = os.path.abspath(target_dir)
        self.languages = languages
        self.languages_str = ", ".join((f'"{l}"' for l in self.languages.split(",")))
        self.project_path_name = self.project_name.replace(".", "-").lower()
        self.variable_prefix = (
            self.project_name.replace(".", "_").replace("-", "_").upper()
        )

    def create(self) -> None:
        self.create_project()

    @property
    def config_dir(self) -> str:
        return os.path.join(self.target_dir, "config")

    @property
    def src_dir(self) -> str:
        return os.path.join(self.target_dir, "src")

    @property
    def project_file_path(self) -> str:
        return os.path.join(self.target_dir, self.project_path_name + ".gpr")

    @property
    def constants_project_file_path(self) -> str:
        return os.path.join(self.config_dir, self.project_path_name + "_constants.gpr")

    @property
    def build_script_path(self) -> str:
        return os.path.join(self.target_dir, self.project_path_name + ".gpr.py")

    @property
    def version_path(self) -> str:
        return os.path.join(self.target_dir, "VERSION")

    def create_project(self) -> None:
        with open(self.version_path, "w") as fd:
            fd.write("0.0.1")

        mkdir(self.config_dir)
        with open(self.constants_project_file_path, "w") as fd:
            fd.write(CONFIG_PROJECT_TEMPLATE.format(**locals()))
        with open(self.build_script_path, "w") as fd:
            fd.write(BUILD_SCRIPT_TEMPLATE.format(**locals()))
        with open(
            os.path.join(self.src_dir, self.project_path_name + ".ads"), "w"
        ) as fd:
            fd.write(f"package {self.project_name} is\nend {self.project_name};\n")
        with open(self.project_file_path, "w") as fd:
            fd.write(PROJECT_TEMPLATE.format(**locals()))
        mkdir(self.src_dir)

        mkdir(os.path.join(self.target_dir, "testsuite", "tests"))
        with open(os.path.join(self.target_dir, "testsuite", "run-tests"), "w") as fd:
            fd.write(TESTSUITE_SCRIPT.format(**locals()))


def main() -> int:
    m = Main()
    m.argument_parser.add_argument("--target-dir")
    m.argument_parser.add_argument("--project-name")
    m.argument_parser.add_argument("--languages", default="Ada")
    m.parse_args()
    alp = AdaLibProject(
        target_dir=m.args.target_dir,
        project_name=m.args.project_name,
        languages=m.args.languages,
    )
    alp.create()
    return 0


if __name__ == "__main__":
    sys.exit(main())
