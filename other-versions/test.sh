#!/bin/bash

# Check if the file path argument is provided
if [ -z "$1" ]; then
  echo "Error: File path argument is missing."
  exit 1
fi

# Set package name and the file path
PKGNAME="$1"
FILEPATH="$PKGNAME"".spec"
wget "https://src.fedoraproject.org/rpms/neofetch/blob/f37/f/$FILEPATH"

echo "$FILEPATH"
echo "$PKGNAME"
