#!/bin/bash

APPDIR="./AppDir"


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

echo "Symlink created to ${image_file}."
