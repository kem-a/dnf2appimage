#!/bin/bash

if [ $# -ne 1 ]; then
  echo "Usage: $0 <rpm-file>"
  exit 1
fi

OUTPUT_DIR="."
PACKAGE_NAME="$1"

# download the source RPM package
toolbox run dnf download --quiet --source "$PACKAGE_NAME" --downloaddir "$OUTPUT_DIR"

# extract the full package name from the downloaded file
rpm_file=$(find $OUTPUT_DIR -name "${PACKAGE_NAME}*.src.rpm")
rpm_file="${rpm_file#./}"

spec_file=$(rpm -qp --qf '%{NAME}.spec\n' "$rpm_file")

if [ -z "$spec_file" ]; then
  echo "Error: Failed to extract .spec file from $rpm_file"
  exit 1
fi

rpm2cpio "$rpm_file" | cpio -i --quiet "$spec_file"

if [ ! -f "$spec_file" ]; then
  echo "Error: Failed to extract $spec_file from $rpm_file"
  exit 1
fi

echo "Successfully extracted $spec_file from $rpm_file"
rm -f "$rpm_file"
