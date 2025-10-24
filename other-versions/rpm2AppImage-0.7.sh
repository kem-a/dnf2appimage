#!/bin/bash

# Check if the file path argument is provided
if [ -z "$1" ]; then
  echo "Error: File path argument is missing."
  exit 1
fi

OUTPUT_DIR="_src"
RPMS_DIR="_rpms"
PACKAGE_NAME="$1"

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

# Initialize variables
EXCLUDE="meson|vala|valadoc|make|cmake|gcc-c++"
REQUIREMENTS=""

# loop through each line in the file
while IFS= read -r line; do
  # check if the line contains "BuildRequires"
  if [[ $line =~ ^(BuildRequires|Requires|Recommends):.* ]]; then
    # check if the line contains "()"
    if [[ "$line" == *"("* ]]; then
        # extract the REQUIREMENTS between the parentheses
        text=$(echo $line | sed 's/.*(\([^)]*\)).*/\1/')
    else
        # extract the REQUIREMENTS after the colon
        text=$(echo "$line" | awk -F':' '{print $2}' | awk '{$1=$1};1' | awk '{print $1}')
    fi
    # check if REQUIREMENTS is not empty and not in EXCLUDE list
    if [[ ! -z "$text" && ! "$EXCLUDE" =~ $text ]]; then
        if ! rpm -qa | grep -q "$text"; then
            text=$(echo "$text" | tr -d '+-' | cut -d'.' -f1)
            echo "Testing... $text"
            REQUIREMENTS="$REQUIREMENTS ${text#*=}"
        fi
            output+=" $text"
    fi
  fi
done < "$FILEPATH"

# text cleanup
OUTPUT="$PACKAGE_NAME $REQUIREMENTS"
#OUTPUT=${OUTPUT/%\{name\}/}
OUTPUT=$(echo "$OUTPUT" | sed 's/ %{name} //g')
#OUTPUT="${OUTPUT/  / }"

echo "Line 80 list of packages to download:$OUTPUT"
##### END GET DEPENDENCIES SECTION

# DOWNLOAD DEP PACKAGES
if [ -n "$OUTPUT" ]; then
  MISSING_PACKAGES=""
  for PKG in $OUTPUT; do
    if ! rpm -q "$PKG" >/dev/null; then
      echo "Downloading... $PKG"
      toolbox run dnf download --quiet --arch=x86_64,noarch --downloaddir=$RPMS_DIR "$PKG"
      MISSING_PACKAGES="$MISSING_PACKAGES $PKG"
    fi
  done
  if [ -n "$MISSING_PACKAGES" ]; then
    echo "Packages downloaded: $MISSING_PACKAGES"
  fi
fi
# END DOWNLOAD PACKAGES

# EXTRACT ALL PACKAGES TO APPDIR
# Make AppDir folder
if [ -d "AppDir" ]; then
  rm -rf "AppDir"
fi
mkdir "AppDir"

# Loop through all RPM files in cache folder
for rpm_file in $RPMS_DIR/*.rpm; do
  # Extract RPM file to tmp folder
  echo "Extracting $rpm_file to AppDir"
  #rpm2cpio "$rpm_file" | (cd AppDir && cpio -idm)

  # Find extracted package and copy to AppDir folder
  #pkg_file=$(find cache/ -name '*.rpm')
  #if [ -z "$pkg_file" ]; then
  #  echo "Error: Package file not found in $rpm_file"
  #else
  #  rsync -avh "$pkg_file" AppDir/usr
  #fi

  # Remove extracted package file
  #rm -f "$pkg_file"
done

# Remove cache folder
#rm -rf $RPMS_DIR
#rm -f "$FILEPATH"
