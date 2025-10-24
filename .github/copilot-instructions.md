# Copilot Instructions for `dnf2appimage`

## Overview
This repository provides tools and scripts to convert RPM packages into AppImages. The structure and scripts are tailored for specific workflows, so understanding the repository layout and conventions is essential for contributing effectively.

## Repository Structure
- **`liveusb-creator.AppDir/`**: Contains an example AppDir structure, including binaries, libraries, and configuration files.
- **`other-versions/`**: Hosts multiple versions of the `rpm2AppImage` script. Use these scripts to convert RPM packages into AppImages.
- **`resources/`**: Pre-configured resources for specific applications like `freerdp` and `Powershell`.
- **`sync-all` and `sync-deps`**: Scripts for synchronizing dependencies.

## Key Workflows

### Creating an AppImage
1. Select the appropriate `rpm2AppImage` script from the `other-versions/` directory.
2. Run the script with the path to the RPM package:
   ```bash
   ./other-versions/rpm2AppImage-0.1.sh path/to/package.rpm
   ```
3. The resulting AppImage will be created in the current directory.

### Example: Packaging `freerdp`
```bash
./other-versions/rpm2AppImage-0.1.sh resources/freerdp/freerdp-2.9.0-1.fc37.x86_64.rpm
```

## Project-Specific Conventions
- **Script Versions**: Multiple versions of `rpm2AppImage` are maintained for compatibility with different RPM packages. Always verify which version works best for your use case.
- **AppDir Structure**: Follow the example in `liveusb-creator.AppDir/` for organizing files when creating new AppImages.
- **Resource Management**: Place application-specific resources in the `resources/` directory.

## External Dependencies
- **`dnf`**: Used for managing RPM packages.
- **`bash`**: Required for running the scripts.

## Tips for Development
- Test scripts in the `tmp/` directory to avoid cluttering the main workspace.
- Use the `sync-all` and `sync-deps` scripts to ensure all dependencies are up-to-date before creating AppImages.

## Contribution Guidelines
- Follow the repository structure and conventions.
- Document any new scripts or workflows in the `README.md`.
- Ensure compatibility with the existing `rpm2AppImage` scripts.

For more details, refer to the [README.md](../README.md).