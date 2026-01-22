# Copilot Instructions for `dnf2appimage`

## Overview
`dnf2appimage` is a toolset for converting RPM packages into AppImages. It uses `dnf` (via `toolbox`) to resolve and download dependencies, extracts them into an AppDir structure, and packages them using `appimagetool`.

## Big Picture Architecture
- **Main Entry Point**: [dnf2appimage](../dnf2appimage) is the primary script that orchestrates the entire process.
- **Dependency Management**: Uses `toolbox run dnf download` to fetch RPMs and their dependencies into a `tmp/` directory.
- **Extraction**: Uses `rpm2cpio` and `cpio` to extract RPM contents into a `.AppDir` folder.
- **Bundling**: Resources from [resources/](../resources/) (like `AppRun`, `.desktop` files, and icons) are merged into the AppDir.
- **Packaging**: Calls `appimagetool` to generate the final `.AppImage` file.

## Critical Workflows
- **Creating an AppImage**: Run `./dnf2appimage <package_name>`. This will create `<package_name>.AppDir` and then the final AppImage.
- **Manual Dependency Sync**: Use [sync-deps](../sync-deps) or [sync-all](../sync-all) if you already have RPMs in `tmp/` and want to update an existing AppDir.
- **Environment Setup**: The [AppRun-bash](../resources/AppRun-bash) script defines the runtime environment (PATH, LD_LIBRARY_PATH, etc.) for the AppImage.

## Project-Specific Conventions
- **Toolbox Usage**: Always use `toolbox` for `dnf` commands to ensure a consistent environment and avoid host system conflicts.
- **AppDir Structure**: Follow the standard AppDir layout: `usr/bin`, `usr/lib64`, `usr/share`, etc.
- **Resource Management**: Place generic or fallback resources (like `terminal.desktop`) in [resources/](../resources/).
- **Extraction Pattern**: `rpm2cpio "$rpm_file" | (cd "$APPDIR" && cpio -idm)` is the standard way to extract packages.

## External Dependencies
- `toolbox`: Required for running `dnf` in a containerized environment.
- `dnf`: Used for package resolution and downloading.
- `rpm2cpio` & `cpio`: Used for extracting RPM packages.
- `appimagetool`: Required to bundle the AppDir into an AppImage.

## Tips for Development
- When modifying [dnf2appimage](../dnf2appimage), ensure that icon and desktop file discovery logic remains robust.
- Test new AppImages on different distributions to verify that [AppRun-bash](../resources/AppRun-bash) environment variables are sufficient.
