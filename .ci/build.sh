#!/bin/bash
set -x
set -e
# Put gnat and gprbuild in the PATH
export PATH=`pwd`/.build/installs/bin:$PATH

cd .build
mkdir -p test
cd test
python3 -m venv venv
export PATH=`pwd`/venv/bin:$PATH
pip install e3-testsuite
../../nstd.gpr.py build --install --prefix=`pwd`/install --finalization=relaxed
export GPR_PROJECT_PATH=`pwd`/install/share/gpr:$GPR_PROJECT_PATH
../../testsuite/run-tests -o ./out -d ./tmp
