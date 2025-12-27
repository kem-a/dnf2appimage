# dnf2appimage

## Overview
`dnf2appimage` is a toolset for converting RPM packages into AppImages. It uses `dnf` (via `toolbox` or natively) to resolve and download dependencies, extracts them into an AppDir structure, and packages them using `appimagetool`.

## Features
- **Automatic Dependency Resolution**: Uses `dnf` to fetch all required RPMs.
- **Toolbox Integration**: Automatically detects and runs inside `toolbox` to keep your host system clean.
- **Metadata Extraction**: Automatically pulls version, description, and homepage from `metainfo.xml`.
- **Smart Icon Discovery**: Locates application icons in standard paths (`hicolor`, `pixmaps`) and sets up `.DirIcon`.
- **Local RPM Support**: Can build AppImages from local `.rpm` files or repository package names.
- **Desktop File Normalization**: Automatically fixes `Icon=` and `Exec=` paths for AppImage compatibility.

## Prerequisites
- Linux OS
- `toolbox` (recommended) or `dnf`, `rpm2cpio`, `cpio`
- `appimagetool` (should be in your `PATH`)

## Usage
```bash
./dnf2appimage [OPTIONS] <package_name_or_rpm>
```

### Options
- `--help`: Show help message.
- `--version`: Show version information.
- `--debug`: Keep the build directory (`.AppDir`) after a successful build.

### Examples
**Build from repository:**
```bash
./dnf2appimage htop
```

**Build from local RPM:**
```bash
./dnf2appimage slack-4.47.69-0.1.el8.x86_64.rpm
```

**Debug build (keep AppDir):**
```bash
./dnf2appimage --debug htop
```

## How it Works
1. **Preparation**: Creates a temporary build environment and a `.AppDir` folder.
2. **Download**: Uses `dnf download --resolve` to fetch the target package and all its dependencies.
3. **Extraction**: Extracts all RPMs into the AppDir structure.
4. **Finalization**: 
   - Symlinks the `.desktop` file and icon to the AppDir root.
   - Fixes absolute paths in the `.desktop` file.
   - Injects metadata from `metainfo.xml`.
   - Adds the `AppRun` entry point.
5. **Packaging**: Runs `appimagetool` to generate the final `.AppImage` file.
6. **Cleanup**: Removes the build directory (unless `--debug` is used).

## Repository Structure
```
dnf2appimage/
├── dnf2appimage      # Main orchestration script
├── sync-all          # Helper to sync all dependencies
├── sync-deps         # Helper to sync missing dependencies
├── resources/        # Generic resources (AppRun, fallback icons, etc.)
└── LICENSE           # MIT License
```

## Contributing
Contributions are welcome! Feel free to open an issue or submit a pull request.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
