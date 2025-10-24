#!/bin/bash

# Check if the file path argument is provided
if [ -z "$1" ]; then
  echo "Error: File path argument is missing."
  exit 1
fi

# Initialize variables
OUTPUT_DIR="_src"
PACKAGE_NAME="$1"
EXCLUDE="meson|vala|valadoc|make|cmake|gcc-c++"
text=""
SPEC_DEPS=""

##### SPEC FILE SECTION
# download the source RPM package to get .spec file
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
rm -f "$rpm_file"
##### END SPEC FILE SECTION

##### GET DEPENDENCIES SECTION
# Set the file path
FILEPATH="$spec_file"

# loop through each line in the file
while IFS= read -r line; do
  # check if the line contains "BuildRequires"
  if [[ $line =~ ^(BuildRequires|Requires|Recommends):.* ]]; then
    # extract the text after the colon
    text=$(echo "$line" | awk -F':' '{print $2}' | awk '{$1=$1};1' | awk '{print $1}')
    # check if text is not empty and not in EXCLUDE list
    if [[ -n "$text" && ! "$EXCLUDE" =~ $text ]]; then
        SPEC_DEPS+=" $text"
    fi
  fi
done < "$FILEPATH"

echo "List of all dependencies:" "$SPEC_DEPS"

##### END GET DEPENDENCIES SECTION
