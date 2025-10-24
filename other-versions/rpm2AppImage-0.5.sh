#!/bin/bash

# Check if the file path argument is provided
if [ -z "$1" ]; then
  echo "Error: File path argument is missing."
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

rm -f "$rpm_file"

# Set the file path
FILEPATH="$spec_file"

# Initialize variables
REQUIREMENTS=""
RECOMMENDATIONS=""

# Read the file line by line
while read line; do

  # Check if the line starts with "Requires"
  if [[ $line == Requires* ]]; then
    # Extract the value after "Requires", delimit by colon, trim, and keep the first value
    REQUIREMENT=$(echo "$line" | awk -F':' '{print $2}' | awk '{$1=$1};1' | awk '{print $1}')
    # Run rpm -qa | grep with the requirement without the prefix
    if ! rpm -qa | grep -q "$REQUIREMENT"; then
      REQUIREMENTS="$REQUIREMENTS ${REQUIREMENT#*=}"
    fi
  fi

  # Check if the line starts with "Recommends"
  if [[ $line == Recommends* ]]; then
    # Extract the value after "Recommends", delimit by colon, trim, and keep the first value
    RECOMMENDATION=$(echo "$line" | awk -F':' '{print $2}' | awk '{$1=$1};1' | awk '{print $1}')
    # Run rpm -qa | grep with the recommendation without the prefix
    if ! rpm -qa | grep -q "$RECOMMENDATION"; then
      RECOMMENDATIONS="$RECOMMENDATIONS ${RECOMMENDATION#*=}"
    fi
  fi

done < "$FILEPATH"

# Print the combined output
OUTPUT=""
if [ -n "$REQUIREMENTS" ]; then
  OUTPUT="$REQUIREMENTS"
fi
if [ -n "$RECOMMENDATIONS" ]; then
  if [ -n "$OUTPUT" ]; then
    OUTPUT="$OUTPUT "
  fi
  OUTPUT="$OUTPUT$RECOMMENDATIONS"
fi

OUTPUT="$PACKAGE_NAME $OUTPUT"

if [ -n "$OUTPUT" ]; then
  MISSING_PACKAGES=""
  for PKG in $OUTPUT; do
    if ! rpm -qa | grep -q "$PKG"; then
      #if rpm -q "$PKG" | grep -q x86_64; then
        toolbox run dnf download --arch=x86_64 --downloaddir=./cache "$PKG"
        MISSING_PACKAGES="$MISSING_PACKAGES $PKG"
      #fi
    fi
  done
  if [ -n "$MISSING_PACKAGES" ]; then
    echo "Packages downloaded: $MISSING_PACKAGES"
  fi
fi

# Make cache & AppDir folders
mkdir -p cache
mkdir -p AppDir

# Loop through all RPM files in cache folder
for rpm_file in cache/*.rpm; do
  # Extract RPM file to tmp folder
  rpm2cpio "$rpm_file" | (cd AppDir && cpio -idm)

  # Find extracted package and copy to AppDir folder
  pkg_file=$(find AppDir/ -name '*.x86_64.rpm')
  if [ -z "$pkg_file" ]; then
    echo "Error: Package file not found in $rpm_file"
  else
    rsync -avh "$pkg_file" AppDir/usr
  fi

  # Remove extracted package file
  rm -f "$pkg_file"
done

# Remove cache folder
rm -rf cache
rm -f "$FILEPATH"
