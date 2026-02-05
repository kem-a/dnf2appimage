# dnf2appimage

## Overview

`dnf2appimage` is a toolset for converting RPM packages into portable AppImages. It uses `dnf` (via `toolbox`) to resolve and download dependencies, extracts them into an AppDir structure, and packages them using modern FUSE-less technology (DwarFS + uruntime).

## Features

- **Automatic Dependency Resolution**: Uses `dnf5` to fetch all required RPMs with full dependency resolution.
- **Toolbox Integration**: Uses `toolbox` for `dnf` commands to ensure a consistent environment and avoid host system conflicts.
- **Minimal Mode (Default)**: Only bundles dependencies not already installed on the host system, resulting in smaller AppImages.
- **Excludelist Support**: Automatically excludes base system packages that should never be bundled.
- **FUSE-less AppImages**: Uses DwarFS + uruntime for packaging - no FUSE required to run AppImages.
- **Metadata Extraction**: Automatically pulls version, description, and homepage from `metainfo.xml`.
- **Smart Icon Discovery**: Locates application icons in standard paths (`hicolor`, `pixmaps`) and sets up `.DirIcon`.
- **Local RPM Support**: Can build AppImages from local `.rpm` files or repository package names.
- **Desktop File Normalization**: Automatically fixes `Icon=` and `Exec=` paths for AppImage compatibility.
- **DBus App Support**: Automatically fixes DBus-activated apps (gapplication launch) for AppImage compatibility.
- **GSettings Schema Compilation**: Compiles GSettings schemas if present in the package.
- **App-Specific Fixes**: Extensible fix system for apps requiring special handling (GJS apps, GIMP, etc.).
- **Optimized Library Loading**: Generates `lib.path` for fast library discovery at runtime.

## Prerequisites

- Linux OS (Fedora, RHEL, Debian, Ubuntu, Arch, openSUSE, and derivatives)
- `toolbox` (auto-installation offered if missing)
- `curl` (for downloading runtime components)

The following tools are automatically downloaded if not present:

- `uruntime` - FUSE-less AppImage runtime
- `mkdwarfs` (dwarfs-universal) - DwarFS filesystem creator

## Usage

```bash
./dnf2appimage [OPTIONS] <package_name_or_rpm>
```

### Options

| Option | Description |
| ------ | ----------- |
| `--help` | Show help message and exit |
| `--version` | Show version information |
| `--debug` | Keep the build directory (`.AppDir`) after a successful build |
| `--full` | Bundle all dependencies (default: only bundle deps not on host) |
| `--extra <pkg,...>` | Additional packages to bundle (comma-separated, mutually exclusive with `--full`) |

### Examples

**Build from repository (minimal mode - default):**

```bash
./dnf2appimage htop
```

**Build from local RPM:**

```bash
./dnf2appimage slack-4.47.69-0.1.el8.x86_64.rpm
```

**Build with all dependencies (full mode):**

```bash
./dnf2appimage --full krita
```

**Debug build (keep AppDir for inspection):**

```bash
./dnf2appimage --debug htop
```

**Bundle extra packages (for missing runtime libraries):**

```bash
./dnf2appimage --extra ffmpeg-libs,libva nextcloud-client
```

## Contributing

Contributions are welcome! Feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
