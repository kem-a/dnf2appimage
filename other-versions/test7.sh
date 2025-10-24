#!/bin/bash

# Get list of build dependencies from spec file
deps=$(sed -n -e '/^BuildRequires:/p' geary.spec | sed 's/BuildRequires://')

# Install build dependencies using dnf
mkdir -p rpms
for p in $deps
do
echo "dependencies " $p
  #toolbox run dnf install -y ${p%-*} --downloadonly --downloaddir=rpms
done
