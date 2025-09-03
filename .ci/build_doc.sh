#!/bin/bash
mkdir -p .build_doc
cd .build_doc
python3 -m venv venv
export PATH=`pwd`/venv/bin:$PATH
pip install sphinx sphinx_rtd_theme
cd ../docs
make html
