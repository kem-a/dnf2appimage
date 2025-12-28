sync-deps and sync-all

Overview

- sync-deps: Extracts only RPMs in `tmp/` that are not already installed on the host. Useful to bring missing dependencies into `<pkg>.AppDir` without bundling packages that are already present on the system.

- sync-all: Extracts all RPMs found in `tmp/` into `<pkg>.AppDir`. Useful to create a fully self-contained AppDir.

Common behavior / flags

Both scripts now support the following options:

- `--dry-run`: Show actions that would be performed without extracting files or deleting any files in `tmp/`.
- `--keep-tmp`: Do not delete `tmp/*.rpm` after successful extraction.
- `--verbose`: Show additional informational messages.
- `--help`: Show usage information.

Notes & caveats

- The scripts use `rpm -qp --qf '%{NAME}'` to reliably extract the package `NAME` field from each RPM. If querying fails (corrupt or non-RPM file), a fallback heuristic strips the filename before the first `-` and uses that as the package name.
- The scripts use `shopt -s nullglob` so loops do nothing when there are no RPM files in `tmp/`.
- When `--dry-run` is used, the scripts will *not* delete files in `tmp/` and will not perform extraction.
- Extraction failures are treated as errors (non-zero exit code) so CI and automation can detect issues.

Safety

- These scripts operate on files in the `tmp/` directory; ensure `tmp/` is not a shared or production directory to avoid race conditions.
- `rpm2cpio | cpio -idm` is used to extract RPMs; malformed RPMs will lead to extraction failure.

Suggested workflow

1. Use `dnf download --resolve --destdir=tmp <pkg>` to populate `tmp/`.
2. Use `./sync-deps --dry-run --verbose <pkg>` to check what would be extracted.
3. Run `./sync-deps --verbose <pkg>` (or `./sync-all`) to perform extraction.
4. If needed, re-run with `--keep-tmp` to retain RPMs in `tmp/` for debugging.
