#!/bin/bash
# App-specific fixes for dnf2appimage
# This file contains patches and fixes for specific applications
# that need special handling to work correctly in an AppImage.

# Usage: source this file from dnf2appimage after extracting packages
# Required variables: APPDIR, TOOLBOX_RUN

apply_app_fixes() {
    local APPDIR="$1"
    local TOOLBOX_RUN="$2"
    
    echo "Applying app-specific fixes..."
    
    # Fix GJS apps - patch prefix to be relocatable
    # GJS apps use imports.package.init({ prefix: "/usr" }) which is hardcoded
    fix_gjs_apps "$APPDIR"
    
    # Fix GIMP interpreter files and setup environment
    fix_gimp_interpreters "$APPDIR"
    setup_gimp_env "$APPDIR"
    
    # Setup GNOME Weather (libgweather) environment
    setup_gweather_env "$APPDIR"
}

# GJS (GNOME JavaScript) apps need their prefix patched for relocatability
fix_gjs_apps() {
    local APPDIR="$1"
    
    for gjs_script in $(find "$APPDIR/usr/share" -maxdepth 2 -type f -name "org.gnome.*" 2>/dev/null); do
        if head -1 "$gjs_script" | grep -q "gjs"; then
            echo "Patching GJS app: $(basename "$gjs_script")"
            
            # Rename original script
            mv "$gjs_script" "${gjs_script}.original"
            
            # Create wrapper script that sets APPIMAGE_USR for the patched script
            cat > "$gjs_script" << 'WRAPPER_EOF'
#!/bin/bash
# GJS wrapper for AppImage
# Get the real path of this script (resolving symlinks)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
SCRIPT_NAME="$(basename "$SCRIPT_PATH")"

# Set APPIMAGE_USR to the /usr prefix inside the AppImage
# This goes from /xxx/usr/share/org.gnome.AppId -> /xxx/usr
export APPIMAGE_USR="${SCRIPT_DIR}/../.."

# Execute the original GJS script with the bundled interpreter
# The AppRun sets up GI_TYPELIB_PATH already
if [ -x "${SCRIPT_DIR}/../../bin/gjs-console" ]; then
    exec "${SCRIPT_DIR}/../../bin/gjs-console" "${SCRIPT_DIR}/${SCRIPT_NAME}.original" "$@"
elif [ -x "${SCRIPT_DIR}/../../bin/gjs" ]; then
    exec "${SCRIPT_DIR}/../../bin/gjs" "${SCRIPT_DIR}/${SCRIPT_NAME}.original" "$@"
else
    # Fallback to system gjs
    exec gjs "${SCRIPT_DIR}/${SCRIPT_NAME}.original" "$@"
fi
WRAPPER_EOF
            chmod +x "$gjs_script"
            
            # Patch the original script to use APPIMAGE_USR environment variable if set
            # This replaces prefix: "/usr" with dynamic path from environment
            # We need to import GLib first to access environment variables
            sed -i '1a\const GLib = imports.gi.GLib;' "${gjs_script}.original"
            sed -i 's#prefix: "/usr"#prefix: GLib.getenv("APPIMAGE_USR") || "/usr"#' "${gjs_script}.original"
            echo "GJS app patched for relocatability"
        fi
    done
}

# GIMP interpreter files have hardcoded /usr/bin paths that need to be fixed
# so GIMP will find interpreters via PATH (which AppRun sets up)
fix_gimp_interpreters() {
    local APPDIR="$1"
    
    for interp_dir in "$APPDIR/usr/lib64/gimp/"*/interpreters "$APPDIR/usr/lib/gimp/"*/interpreters; do
        if [ -d "$interp_dir" ]; then
            for interp_file in "$interp_dir"/*.interp; do
                [ -f "$interp_file" ] || continue
                echo "Fixing GIMP interpreter file: $(basename "$interp_file")"
                # Replace /usr/bin/something with just "something" so PATH lookup works
                sed -i 's|=/usr/bin/|=|g' "$interp_file"
                sed -i 's|=/usr/sbin/|=|g' "$interp_file"
                sed -i 's|=/bin/|=|g' "$interp_file"
            done
        fi
    done
}

# Create AppRun environment snippet for GIMP
# This creates a file that AppRun can source at runtime
setup_gimp_env() {
    local APPDIR="$1"
    
    if [ -d "$APPDIR/usr/share/gimp" ]; then
        echo "Setting up GIMP environment..."
        GIMP_VER=$(ls "$APPDIR/usr/share/gimp/" | head -1)
        
        cat > "$APPDIR/gimp-env.sh" << EOF
# GIMP environment variables (auto-generated)
# GEGL/BABL (GIMP image processing)
export GEGL_PATH="\${HERE}/usr/lib64/gegl-0.4/:\${HERE}/usr/lib/gegl-0.4/\${GEGL_PATH:+:\$GEGL_PATH}"
export BABL_PATH="\${HERE}/usr/lib64/babl-0.1/:\${HERE}/usr/lib/babl-0.1/\${BABL_PATH:+:\$BABL_PATH}"

# GIMP paths
export GIMP3_DATADIR="\${HERE}/usr/share/gimp/${GIMP_VER}"
export GIMP3_LOCALEDIR="\${HERE}/usr/share/locale"
export GIMP3_SYSCONFDIR="\${HERE}/etc/gimp/${GIMP_VER}"
if [ -d "\${HERE}/usr/lib64/gimp/${GIMP_VER}" ]; then
  export GIMP3_PLUGINDIR="\${HERE}/usr/lib64/gimp/${GIMP_VER}"
else
  export GIMP3_PLUGINDIR="\${HERE}/usr/lib/gimp/${GIMP_VER}"
fi
EOF
        echo "GIMP environment file created"
    fi
}

# Create AppRun environment snippet for GNOME Weather (libgweather)
setup_gweather_env() {
    local APPDIR="$1"
    
    if [ -f "$APPDIR/usr/lib64/libgweather-4/Locations.bin" ] || [ -f "$APPDIR/usr/lib/libgweather-4/Locations.bin" ]; then
        echo "Setting up libgweather environment..."
        
        cat > "$APPDIR/gweather-env.sh" << 'EOF'
# libgweather environment variables (auto-generated)
if [ -f "${HERE}/usr/lib64/libgweather-4/Locations.bin" ]; then
  export LIBGWEATHER_LOCATIONS_PATH="${HERE}/usr/lib64/libgweather-4/Locations.bin"
elif [ -f "${HERE}/usr/lib/libgweather-4/Locations.bin" ]; then
  export LIBGWEATHER_LOCATIONS_PATH="${HERE}/usr/lib/libgweather-4/Locations.bin"
fi
EOF
        echo "libgweather environment file created"
    fi
}
