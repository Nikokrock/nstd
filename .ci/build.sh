#!/bin/bash
set -x
set -e

if [ "$GITHUB_STEP_SUMMARY" != "" ]; then
   enable_github_reporting="true"
else
   enable_github_reporting="false"
fi

# Put gnat and gprbuild in the PATH
export PATH=`pwd`/.build/installs/bin:$PATH

cd .build
mkdir -p test
cd test
python3 -m venv venv
export PATH=`pwd`/venv/bin:$PATH
pip install e3-testsuite
../../nstd.gpr.py build --install --prefix=`pwd`/install --finalization=relaxed 2>&1 | \
   sed -e "s/^\(..*\):\([0-9]*\):\([0-9]*\): *warning: *\(.*\)/::warning file=\1,line=\2::\4/g"

export GPR_PROJECT_PATH=`pwd`/install/share/gpr:$GPR_PROJECT_PATH
../../testsuite/run-tests -o ./out -d ./tmp
