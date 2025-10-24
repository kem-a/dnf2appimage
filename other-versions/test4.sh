#!/bin/bash

APPDIR="./AppDir"

if [ -d "$APPDIR/usr/share/applications/" ]; then
    desktop_file=$(find "$APPDIR/usr/share/applications/" -name "*.desktop" -print -quit)
    if [ -n "$desktop_file" ]; then
        symlink_file=$(basename "$desktop_file")
        desktop_file=${desktop_file#"$APPDIR"/}
        #ln -s "$desktop_file" "$APPDIR/$symlink_file"
        echo "Created symlink for $symlink_file in AppDir"
    else
        echo "No .desktop file found in AppDir/usr/share/applications/"
    fi
else
    echo "AppDir/usr/share/applications/ directory does not exist"
fi

# Check for image files in IMAGE_DIR1 and create symlinks in AppDir
# 
# Check if hicolor directory exists
if [ ! -d "$APPDIR/usr/share/icons/hicolor" ]; then
    echo "hicolor directory does not exist."
    exit 1
fi

# Find image files in hicolor directory
image_files=$(find "$APPDIR/usr/share/icons/hicolor" -type f \( -name "*.png" -o -name "*.svg" \))

# Check if any image files were found
if [ -z "${image_files}" ]; then
    echo "No image files found in hicolor directory."
    exit 1
fi

# Create symlink to first image file found
image_file=$(echo "${image_files}" | tail -n1)
symlink_file=$(basename "$image_file")
image_file=${image_file#"$APPDIR"/}
ln -s "${image_file}" "${APPDIR/$symlink_file}"
ln -s "${symlink_file}" "$APPDIR/.DirIcon"
echo "Symlink created to ${image_file}."

cp -n resources/AppRun "$APPDIR"

# Check if the file already exists in the AppDir
if [ ! "$(find "$APPDIR" -maxdepth 1 -name '*.desktop' -print -quit)" ]; then
  # Copy the file to the AppDir
  cp -n "resources/terminal.desktop" "${APPDIR}/"
  echo "Warning: copied generic desktop file 'terminal.desktop' tp AppDir.Please edit correct values."
fi


