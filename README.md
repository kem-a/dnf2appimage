# dnf2appimage

## Overview
`dnf2appimage` is a toolset designed to facilitate the creation of AppImages from RPM packages. It provides scripts and resources to streamline the process of converting RPM-based applications into portable AppImages, making them easier to distribute and use across various Linux distributions.

## Features
- Convert RPM packages to AppImages.
- Synchronize dependencies for AppImage creation.
- Support for multiple versions of the `rpm2AppImage` script.
- Pre-configured resources for specific applications like `freerdp` and `Powershell`.
- Example AppDir structure for reference.

## Repository Structure
```
dnf2appimage/
├── Fedora_Media_Writer-x86_64.AppImage
├── sync-all
├── sync-deps
├── liveusb-creator.AppDir/
│   ├── AppRun
│   ├── etc/
│   │   └── X11/
│   │       └── xinit/
│   ├── xdg/
│   │   └── QtProject/
│   └── usr/
│       ├── bin/
│       │   └── mediawriter
│       ├── lib/
│       ├── lib64/
│       │   ├── libQt6Concurrent.so.6.5.2
│       │   ├── libQt6Core.so.6.5.2
│       │   └── ...
│       ├── libexec/
│       └── share/
├── other-versions/
│   ├── dnf2appimage.sh
│   ├── rpm2AppImage-0.1.sh
│   ├── rpm2AppImage-0.2.sh
│   ├── ...
│   └── test7.sh
├── resources/
│   ├── AppRun
│   ├── terminal.desktop
│   ├── freerdp/
│   │   ├── freerdp-2.9.0-1.fc37.x86_64.rpm
│   │   ├── freerdp-libs-2.9.0-1.fc37.x86_64.rpm
│   │   └── libwinpr-2.9.0-1.fc37.x86_64.rpm
│   └── Powershell/
│       ├── AppRun
│       └── pwsh.desktop
└── tmp/
```

## Getting Started

### Prerequisites
- A Linux-based operating system.
- `bash` shell.
- `dnf` package manager.
- Required dependencies for the application you want to package.

### Usage
1. Clone the repository:
   ```bash
   git clone https://github.com/kem-a/dnf2appimage.git
   cd dnf2appimage
   ```
2. Choose the appropriate `rpm2AppImage` script from the `other-versions/` directory.
3. Run the script with the desired RPM package:
   ```bash
   ./other-versions/rpm2AppImage-0.1.sh path/to/package.rpm
   ```
4. The resulting AppImage will be created in the current directory.

### Example
To create an AppImage for `freerdp`:
```bash
./other-versions/rpm2AppImage-0.1.sh resources/freerdp/freerdp-2.9.0-1.fc37.x86_64.rpm
```

## Contributing
Contributions are welcome! If you have suggestions for improvements or encounter any issues, feel free to open an issue or submit a pull request.

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments
- The AppImage project for providing the foundation for portable Linux applications.
- The Fedora Project for their RPM package ecosystem.