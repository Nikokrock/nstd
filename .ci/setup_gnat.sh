#!/bin/bash
FSF_URL="https://github.com/alire-project/GNAT-FSF-builds/releases/download"

mkdir -p .build/downloads
mkdir -p .build/unpacks
mkdir -p .build/installs

arch="$(uname -p)-$(uname -s)"

case "$arch" in
   amd64-Linux|x86_64-Linux)
      gnat_arch="x86_64-linux";;
   aarch64-Linux)
      gnat_arch="aarch64-linux";;
   *) echo "unsupported arch: $arch"
      exit 1;;
esac

curl -L $FSF_URL/gnat-15.1.0-2/gnat-$gnat_arch-15.1.0-2.tar.gz \
     -o .build/downloads/gnat.tar.gz
curl -L $FSF_URL/gprbuild-25.0.0-1/gprbuild-$gnat_arch-25.0.0-1.tar.gz \
     -o .build/downloads/gprbuild.tar.gz
(
 cd .build/installs
 tar --strip-components=1 -xzf ../downloads/gnat.tar.gz
)
(
 mkdir .build/unpacks/gprbuild
 cd .build/unpacks/gprbuild
 tar --strip-components=1 -xzf ../../downloads/gprbuild.tar.gz
 ./doinstall `pwd`/../../installs
)

