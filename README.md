# wch-cmake

Documentation: <https://guajun.github.io/wch-cmake/>

`wch-cmake` is a repository of CMake templates and executable `.ps1/.sh`
scripts. It is not a compiled program.

MRS2 is used once to select a chip, create the vendor project, and produce an
active build such as `obj/makefile`. The importer reads the exact compiler and
linker recipes that MRS2 generated, then installs a standalone CMake project.
After that import, CMake is the build source of truth.

Probe access is intentionally separate: use the sibling `wchlink-cli` repository
for discovery, flash, GDB Server, and breakpoint checks.

## Import

Build the new project once in MRS2, then run the repository script:

```powershell
& F:\wch\wch-cmake\wch-cmake.ps1 import -Project F:\wch\blink\CH32X035F8U -MrsRoot C:\MounRiver\MounRiver_Studio2
```

The POSIX entry point calls the same `cmake -P` implementation:

```sh
MRS2_ROOT=/opt/mounriver sh /opt/wch-cmake/wch-cmake.sh import --project ./firmware
```

The importer installs `CMakeLists.txt`, presets, the toolchain modules,
`cmake/wch-project.cmake`, VS Code tasks, and shell activation scripts. Local
MRS2 paths are kept in ignored `CMakeUserPresets.json`.

The first supported layouts are WCH RISC-V GCC8, GCC12, and GCC15. Chip-specific
flags, linker script, source order, libraries, device name, OpenOCD config, and
GDB port come from the MRS2 project rather than from a duplicated chip table.

## Build

```powershell
cmake --preset local-release
cmake --build --preset local-release --parallel
```

`release` and `debug` live in the tracked `CMakePresets.json`. The importer
creates an ignored `CMakeUserPresets.json` with `local-release` and
`local-debug`; those presets inherit their tracked counterparts and only add
the current machine's `MRS2_ROOT`. The `local` prefix therefore means
machine-local configuration, not a different build type or artifact scope.

Add new application sources directly to `WCH_SOURCES` in
`cmake/wch-project.cmake`, or use normal `target_sources` and subdirectory
`CMakeLists.txt` files. MRS2 does not need to update its makefile after the
one-time import. Running `import` again is an explicit re-import and replaces
the generated manifest with current MRS2 facts.

C++ is supported. When the vendor startup does not call
`__libc_init_array`, the generated runtime shim wraps `main` so global
constructors still run.

## Verify Migration

```powershell
& F:\wch\wch-cmake\wch-cmake.ps1 verify -Project F:\wch\blink\CH32X035F8U
```

`verify` compares the MRS2 and CMake HEX files, raw load images, and sorted ELF
symbols. For the CH32X035F8U fixture the raw image SHA-256 is
`191677d88a3e44e4cfdf41cfbb4f474026469227a494dcbecd92fa10709ebbf5`.

## Install From A Release

A release contains scripts and templates, not an executable:

```powershell
$installer = irm https://github.com/guajun/wch-cmake/releases/latest/download/install.ps1
& ([scriptblock]::Create($installer)) -Project F:\wch\blink\CH32X035F8U
```

Pin `-Version v0.1.0` in reproducible setup. CMake configure never downloads
mutable project logic.

## Sources Of Truth

- Before import, MRS2 `.template/.launch` and generated makefiles are bootstrap
  inputs.
- After import, `CMakeLists.txt` and `cmake/wch-project.cmake` own the build.
- `CMakeUserPresets.json` owns machine-local paths and is ignored by Git.
- `.project/.cproject/.wvproj` are not consumed during normal CMake builds.
- `wchlink-cli` owns physical probe sessions and has no build-generation code.

The generated `.wch-import-lock.json` records input hashes so later tooling can
detect an intentional or accidental re-import boundary.
