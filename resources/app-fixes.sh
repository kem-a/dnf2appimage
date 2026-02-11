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
    
    # Fix Meson Python apps - patch hardcoded paths
    # Python apps built with Meson have hardcoded pkgdatadir paths
    fix_meson_python_apps "$APPDIR"
    
    # Fix GIMP interpreter files and setup environment
    fix_gimp_interpreters "$APPDIR"
    setup_gimp_env "$APPDIR"
    
    # Setup GNOME Weather (libgweather) environment
    setup_gweather_env "$APPDIR"

    # Setup libreport config bind for ABRT (runtime via bwrap)
    setup_libreport_bwrap "$APPDIR"
}

# GJS (GNOME JavaScript) apps need their prefix patched for relocatability
fix_gjs_apps() {
    local APPDIR="$1"
    
    for gjs_script in $(find "$APPDIR/usr/share" -maxdepth 2 -type f -name "org.gnome.*" 2>/dev/null); do
        if head -1 "$gjs_script" | grep -q "gjs"; then
            echo "Patching GJS app: $(basename "$gjs_script")"
            
            # Get the app ID from the script name (e.g., org.gnome.Maps)
            local app_basename=$(basename "$gjs_script")
            local pkgdatadir=$(dirname "$gjs_script")
            # Get path relative to APPDIR/usr (not APPDIR)
            local pkgdatadir_rel="${pkgdatadir#$APPDIR/usr}"
            
            # Create a patched version of the script using file operations
            # instead of sed to avoid escaping issues
            {
                # Keep the shebang
                head -1 "$gjs_script"
                
                # Add our initialization code
                echo 'const GLib = imports.gi.GLib;'
                echo 'const Gio = imports.gi.Gio;'
                echo 'const _appimage_usr = GLib.getenv("APPIMAGE_USR");'
                echo 'if (_appimage_usr) {'
                echo "    const _pkgdatadir = _appimage_usr + \"${pkgdatadir_rel}\";"
                echo '    ["src", "data", "shields"].forEach(type => {'
                echo '        try {'
                echo "            const f = _pkgdatadir + \"/${app_basename}.\" + type + \".gresource\";"
                echo '            if (GLib.file_test(f, GLib.FileTest.EXISTS))'
                echo '                Gio.resources_register(Gio.Resource.load(f));'
                echo '        } catch(e) {}'
                echo '    });'
                echo '}'
                
                # Add rest of the file (skip shebang)
                tail -n +2 "$gjs_script"
            } > "${gjs_script}.new"
            
            mv "${gjs_script}.new" "$gjs_script"
            chmod +x "$gjs_script"
            
            # Patch prefix and libdir to use APPIMAGE_USR
            sed -i 's#prefix: "/usr"#prefix: GLib.getenv("APPIMAGE_USR") || "/usr"#' "$gjs_script"
            sed -i 's#libdir: "/usr/lib64"#libdir: (GLib.getenv("APPIMAGE_USR") || "/usr") + "/lib64"#' "$gjs_script"
            sed -i 's#libdir: "/usr/lib"#libdir: (GLib.getenv("APPIMAGE_USR") || "/usr") + "/lib"#' "$gjs_script"
            
            echo "GJS app patched for relocatability"
        fi
    done
}

# Meson Python apps have hardcoded paths like:
# pkgdatadir = '/usr/share/appname' (lowercase, e.g., gnome-tweaks)
# PKGDATA_DIR = '/usr/share/appname' (uppercase, e.g., gnome-music)
# localedir/LOCALE_DIR = '/usr/share/locale'
# These need to be made relative to the script location
fix_meson_python_apps() {
    local APPDIR="$1"
    
    for py_script in "$APPDIR/usr/bin/"*; do
        [ -f "$py_script" ] || continue
        
        # Check if it's a Python script with hardcoded paths (lowercase or uppercase)
        if head -1 "$py_script" | grep -q "python"; then
            local needs_patch=false
            local app_name=""
            local use_uppercase=false
            
            # Check for lowercase pattern (pkgdatadir = '/usr/share/...')
            if grep -q "^pkgdatadir = '/usr/share/" "$py_script"; then
                needs_patch=true
                app_name=$(grep "^pkgdatadir = " "$py_script" | sed "s/.*'\\/usr\\/share\\/\\([^']*\\)'.*/\\1/")
                use_uppercase=false
            # Check for uppercase pattern (PKGDATA_DIR = '/usr/share/...')
            elif grep -q "^PKGDATA_DIR = '/usr/share/" "$py_script"; then
                needs_patch=true
                app_name=$(grep "^PKGDATA_DIR = " "$py_script" | sed "s/.*'\\/usr\\/share\\/\\([^']*\\)'.*/\\1/")
                use_uppercase=true
            fi
            
            if [ "$needs_patch" = true ] && [ -n "$app_name" ]; then
                echo "Patching Meson Python app: $(basename "$py_script") (app: $app_name)"
                
                if [ "$use_uppercase" = true ]; then
                    # Handle uppercase variable names (PKGDATA_DIR, LOCALE_DIR)
                    sed -i "
                        # Add imports at the top (after the shebang and any encoding line)
                        /^#!/ {
                            a\\
import os as _appimage_os\\
_script_dir = _appimage_os.path.dirname(_appimage_os.path.realpath(__file__))
                        }
                        
                        # Replace hardcoded PKGDATA_DIR
                        s|^PKGDATA_DIR = '/usr/share/$app_name'|PKGDATA_DIR = _appimage_os.path.join(_script_dir, '..', 'share', '$app_name')|
                        
                        # Replace hardcoded LOCALE_DIR
                        s|^LOCALE_DIR = '/usr/share/locale'|LOCALE_DIR = _appimage_os.path.join(_script_dir, '..', 'share', 'locale')|
                    " "$py_script"
                else
                    # Handle lowercase variable names (pkgdatadir, localedir)
                    sed -i "
                        # Add imports at the top (after the shebang and any encoding line)
                        /^#!/ {
                            a\\
import os as _appimage_os\\
_script_dir = _appimage_os.path.dirname(_appimage_os.path.realpath(__file__))
                        }
                        
                        # Replace hardcoded pkgdatadir
                        s|^pkgdatadir = '/usr/share/$app_name'|pkgdatadir = _appimage_os.path.join(_script_dir, '..', 'share', '$app_name')|
                        
                        # Replace hardcoded localedir
                        s|^localedir = '/usr/share/locale'|localedir = _appimage_os.path.join(_script_dir, '..', 'share', 'locale')|
                    " "$py_script"
                fi
                
                echo "Meson Python app patched for relocatability"
            fi
        fi
    done
    
    # Fix Python apps that use a separate defs.py module with hardcoded paths
    # (e.g., gnome-tweaks has gtweak/defs.py with DATA_DIR, PKG_DATA_DIR, etc.)
    fix_python_defs_modules "$APPDIR"
}

# Fix Python defs.py modules with hardcoded paths (common in GNOME Python apps)
# These modules define constants like DATA_DIR = "/usr/share" that need relocating
fix_python_defs_modules() {
    local APPDIR="$1"
    
    # Find defs.py files in Python site-packages
    for defs_file in $(find "$APPDIR/usr/lib" "$APPDIR/usr/lib64" -path "*/site-packages/*/defs.py" -type f 2>/dev/null); do
        # Check if it has hardcoded /usr paths
        if grep -qE '^(DATA_DIR|PKG_DATA_DIR|LOCALE_DIR|TWEAK_DIR|GSETTINGS_SCHEMA_DIR)\s*=\s*"\/usr' "$defs_file"; then
            echo "Patching Python defs module: $defs_file"
            
            # Get the module directory for relative path calculation
            module_dir=$(dirname "$defs_file")
            module_name=$(basename "$module_dir")
            
            # Create a patched version that computes paths at runtime
            # We'll add path computation code at the top and replace the constants
            
            # First, extract current values to understand the structure
            local pkg_data_dir_val=$(grep '^PKG_DATA_DIR\s*=' "$defs_file" | sed 's/.*=\s*"\([^"]*\)".*/\1/')
            local tweak_dir_val=$(grep '^TWEAK_DIR\s*=' "$defs_file" | sed 's/.*=\s*"\([^"]*\)".*/\1/')
            
            # Create wrapper code that detects AppImage environment
            cat > "${defs_file}.new" << 'DEFS_HEADER'
# AppImage-patched defs.py - paths computed at runtime
import os as _defs_os

# Detect if running from AppImage by checking for APPDIR env var
# or by checking if the module path is not under system /usr
_defs_module_dir = _defs_os.path.dirname(_defs_os.path.realpath(__file__))
_defs_in_appimage = not _defs_module_dir.startswith("/usr/")

if _defs_in_appimage:
    # Running from AppImage - compute paths relative to module location
    # Module is at: <AppDir>/usr/lib/pythonX.Y/site-packages/<module>/defs.py
    # We need to get to: <AppDir>/usr
    _defs_usr_dir = _defs_module_dir
    for _ in range(4):  # Go up: defs.py -> module -> site-packages -> pythonX.Y -> lib -> usr
        _defs_usr_dir = _defs_os.path.dirname(_defs_usr_dir)
    # Now _defs_usr_dir should be at <AppDir>/usr or <AppDir>/usr/lib64's parent
    # Normalize by going to the 'usr' level
    while not _defs_usr_dir.endswith('/usr') and _defs_usr_dir != '/':
        _defs_usr_dir = _defs_os.path.dirname(_defs_usr_dir)
    
    DATA_DIR = _defs_os.path.join(_defs_usr_dir, "share")
    LOCALE_DIR = _defs_os.path.join(_defs_usr_dir, "share", "locale")
    GSETTINGS_SCHEMA_DIR = _defs_os.path.join(_defs_usr_dir, "share", "glib-2.0", "schemas")
DEFS_HEADER

            # Extract app-specific values and add them
            if [ -n "$pkg_data_dir_val" ]; then
                pkg_subdir=$(basename "$pkg_data_dir_val")
                echo "    PKG_DATA_DIR = _defs_os.path.join(_defs_usr_dir, \"share\", \"$pkg_subdir\")" >> "${defs_file}.new"
            fi
            
            if [ -n "$tweak_dir_val" ]; then
                # TWEAK_DIR points to the tweaks subdir in the module
                echo "    TWEAK_DIR = _defs_os.path.join(_defs_module_dir, \"tweaks\")" >> "${defs_file}.new"
            fi
            
            # Add else clause with original values
            echo "else:" >> "${defs_file}.new"
            echo "    # Running from system installation - use original paths" >> "${defs_file}.new"
            
            # Copy original constant definitions (indented under else)
            grep -E '^(DATA_DIR|PKG_DATA_DIR|LOCALE_DIR|TWEAK_DIR|GSETTINGS_SCHEMA_DIR)\s*=' "$defs_file" | \
                sed 's/^/    /' >> "${defs_file}.new"
            
            # Copy remaining non-path constants
            echo "" >> "${defs_file}.new"
            echo "# Non-path constants (unchanged)" >> "${defs_file}.new"
            grep -vE '^(DATA_DIR|PKG_DATA_DIR|LOCALE_DIR|TWEAK_DIR|GSETTINGS_SCHEMA_DIR)\s*=' "$defs_file" >> "${defs_file}.new"
            
            # Replace original file
            mv "${defs_file}.new" "$defs_file"
            
            echo "Python defs module patched for relocatability"
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

# ABRT/libreport needs /etc/libreport to be present at runtime
# Create a generic bwrap bind list for AppRun to consume
setup_libreport_bwrap() {
    local APPDIR="$1"

    if [ -f "$APPDIR/etc/libreport/libreport.conf" ]; then
        local binds_file="$APPDIR/bwrap.binds"

        if [ ! -f "$binds_file" ]; then
            echo "# bwrap binds generated by app-fixes.sh" > "$binds_file"
        fi

        if ! grep -qx "dir /etc/libreport" "$binds_file" 2>/dev/null; then
            echo "dir /etc/libreport" >> "$binds_file"
        fi

        if ! grep -qx "bind etc/libreport /etc/libreport" "$binds_file" 2>/dev/null; then
            echo "bind etc/libreport /etc/libreport" >> "$binds_file"
        fi

        echo "Configured bwrap bind for /etc/libreport"
    fi
}
