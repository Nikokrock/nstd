#!/bin/bash
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
../../nstd/nstd.gpr.py build --install --prefix=`pwd`/install --finalization=relaxed

export GPR_PROJECT_PATH=`pwd`/install/share/gpr:$GPR_PROJECT_PATH
../../testsuite/nstd/run-tests -o ./out -d ./tmp

echo "[Link example](https://$GITHUB_REPOSITORY/nstd/blob/$GITHUB_REF_NAME/nstd/nstd.gpr)" > "$GITHUB_STEP_SUMMARY"
