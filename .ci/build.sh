#!/bin/bash
set -e

if [ "$GITHUB_STEP_SUMMARY" != "" ]; then
   enable_github_reporting="true"
else
   enable_github_reporting="false"
fi

cd .build
mkdir -p test
cd test
python3 -m venv venv
export PATH=`pwd`/venv/bin:$PATH
pip install e3-testsuite

../../nstd/nstd.gpr.py build --install --prefix=`pwd`/install --finalization=relaxed

export GPR_PROJECT_PATH=`pwd`/install/share/gpr:$GPR_PROJECT_PATH


../../nstd_re/nstd_re.gpr.py build --install --prefix=`pwd`/install

exit 1
../../testsuite/nstd/run-tests -o ./out -d ./tmp
# echo "[Link example](https://github.com/$GITHUB_REPOSITORY/blob/$GITHUB_REF_NAME/nstd/nstd.gpr)" > "$GITHUB_STEP_SUMMARY"
