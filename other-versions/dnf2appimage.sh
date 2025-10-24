#!/bin/bash

# Check if the file path argument is provided
if [ -z "$1" ]; then
  echo "Error: File path argument is missing."
  exit 1
fi

# Initialize variables
PKG="$1"
APPDIR="$PKG.AppDir"
EXCLUDE="meson|vala|valadoc|make|cmake|gcc-c++"
text=""
SPEC_DEPS=""


##### GETTING DEPENDENCIES FROM SPEC FILE #####

# download the source RPM package to get .spec file
toolbox run dnf download --quiet --source "$PKG"

# extract the full package name from the downloaded file
rpm_file=$(find . -name "${PKG}*.src.rpm")
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
done < "$spec_file"

#echo "List of all dependencies:" "$SPEC_DEPS"
##### END GET DEPENDENCIES SECTION

# Preparing
# Make AppDir folder
if [ -d "$APPDIR" ]; then
  rm -rf "$APPDIR"
fi
mkdir "$APPDIR"

# Make tmp folder
if [ -d "tmp" ]; then
  rm -rf "tmp"
fi
mkdir "tmp"
toolbox run dnf download --arch=x86_64,noarch --quiet --destdir="$PWD/tmp" "$PKG"
PACKAGE="tmp/$(ls tmp | grep "$PKG")"

# Checking package dependencies and downloading those as rpms
# Install the package with the --test option to check for missing dependencies
if ! rpm -ivh --test "$PACKAGE" &> /dev/null; then

    # Get the list of missing dependencies
    #MISSING_DEPS=$(rpm -ivh --test "$PACKAGE" 2>&1 | awk '/Failed dependencies:/{getline;gsub(/[[:space:]]/,"");print}')
    MISSING_DEPS=$(rpm -ivh --test "$PACKAGE" 2>&1 | awk '/Failed dependencies:/{flag=1; next} /warning:/{flag=0} flag {print $1}' | sed 's/()//g')
    MISSING_DEPS=${MISSING_DEPS//$'\n'/ }
    MISSING_DEPS=$(echo "$MISSING_DEPS" | sed -E 's/\([^)]*\)//g')

    # Convert string to an array
    array=("$MISSING_DEPS")

    # Remove duplicates and convert array back to string
    MISSING_DEPS=$(echo "${array[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' ')
    MISSING_DEPS=$MISSING_DEPS$SPEC_DEPS

    echo "The following dependencies are required for $PKG:"
    echo "$MISSING_DEPS"

    # Loop through each missing dependency
    for DEP in $MISSING_DEPS; do
      PACKAGE_NAME=$(toolbox run dnf provides *"$DEP" | grep -Eo '^[^ ]+' | grep 'x86_64\|noarch' | tail -n 1)
      # Check if the dependency is already installed
      if ! rpm -q "$PACKAGE_NAME" &> /dev/null; then
        # If the dependency is not installed, find the package that provides it and download it
        PROVIDER=$(toolbox run dnf repoquery -q --queryformat '%{NAME}.%{ARCH}\n' "$PACKAGE_NAME" | grep 'x86_64\|noarch' | tr -d '\n' | tr -d '[:space:]')
        echo "Downloading... $PROVIDER"
        toolbox run dnf download --arch=x86_64,noarch --quiet --destdir="$PWD/tmp" "$PROVIDER"
      fi
    done
else
  echo "All dependencies for $PACKAGE are already installed."
fi

# Loop through all RPM files in tmp folder
for rpm_file in tmp/*.rpm; do
  # Extract RPM file to AppDir folder
  echo "Extracting $rpm_file to AppDir"
  rpm2cpio "$rpm_file" | (cd "$APPDIR" && cpio -idm)
done

# Remove temporary folder
#rm -rf tmp

#
# Finalizing AppDir folder by adding required files
#

# Adding .desktop file
if [ -d "$APPDIR/usr/share/applications/" ]; then
    desktop_file=$(find "$APPDIR/usr/share/applications/" -name "*.desktop" -print -quit)
    if [ -n "$desktop_file" ]; then
        symlink_file=$(basename "$desktop_file")
        desktop_file=${desktop_file#"$APPDIR"/}
        ln -s "$desktop_file" "$APPDIR/$symlink_file"
        echo "Created symlink for $symlink_file in AppDir"
    else
        echo "No .desktop file found in AppDir/usr/share/applications/"
    fi
else
    echo "AppDir/usr/share/applications/ directory does not exist"
fi

# Adding generic desktop file if original does not exist
if [ ! "$(find "$APPDIR" -maxdepth 1 -name '*.desktop' -print -quit)" ]; then
  # Copy the file to the AppDir
  cp -n "resources/terminal.desktop" "${APPDIR}/"
  echo "Warning: copied generic desktop file 'terminal.desktop' to AppDir.Please edit correct values."
fi

# Adding icon file in AppDir
# Check if hicolor directory exists
if [ ! -d "$APPDIR/usr/share/icons/hicolor" ]; then
      cp -n "resources/terminal.svg" "${APPDIR}/"
      ln -s "terminal.svg" "$APPDIR/.DirIcon"
      echo "Warning: copied generic icon file 'terminal.svg' to AppDir."
    else
      image_files=$(find "$APPDIR/usr/share/icons/hicolor" -type f \( -name "*.png" -o -name "*.svg" \))
      # Create symlink to first image file found
      image_file=$(echo "${image_files}" | tail -n1)
      symlink_file=$(basename "$image_file")
      image_file=${image_file#"$APPDIR"/}
      ln -s "${image_file}" "${APPDIR/$symlink_file}"
      ln -s "${symlink_file}" "$APPDIR/.DirIcon"
      echo "Symlink created to ${image_file}."
fi

cp -n resources/AppRun "$APPDIR"

# Generating AppImage
echo "Generating AppImage..."
"$PWD/appimagetool" "$APPDIR"
echo "Done."
