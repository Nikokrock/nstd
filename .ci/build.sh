#!/bin/bash
set -x
set -e
# Put gnat and gprbuild in the PATH
export PATH=`pwd`/.build/installs/bin:$PATH

gprbuild -P nstd.gpr
