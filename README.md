# wch-cmake

Documentation: [English](https://guajun.github.io/wch-cmake/) | [中文](https://guajun.github.io/wch-cmake/zh.html)

`wch-cmake` is a repository of CMake templates and executable `.ps1/.sh`
scripts. It is not a compiled program.

MRS2 is used once to select a chip, create the vendor project, and produce an
active build such as `obj/makefile`. The importer reads the exact compiler and
linker recipes that MRS2 generated, then installs a standalone CMake project.
After that import, CMake owns the build. Generated MRS2 settings and user
customizations live in separate files so the MRS2 settings can be refreshed.

Probe access is intentionally separate: use the sibling `wchlink-cli` repository
for discovery, flash, GDB Server, and breakpoint checks.

## Import

Build the new project once in MRS2, then run the repository script:

```powershell
& F:\wch\wch-cmake\wch-cmake.ps1 import -Project F:\wch\blink\CH32X035F8U
```

The POSIX entry point calls the same `cmake -P` implementation:

```sh
sh /opt/wch-cmake/wch-cmake.sh import --project ./firmware
```

The default import writes only `CMakeLists.txt`, `CMakePresets.json`, `cmake/`,
and `scripts/`. Import only reads the MRS2-generated project metadata, so it
does not need a toolchain path. Pass `-WithVSCode` (or `--with-vscode`) to add
the optional `.vscode/tasks.json` integration.

The first supported layouts are WCH RISC-V GCC8, GCC12, and GCC15. Chip-specific
flags, linker script, source order, libraries, device name, OpenOCD config, and
GDB port come from the MRS2 project rather than from a duplicated chip table.

## Build

```powershell
.\scripts\activate.ps1 -MrsRoot C:\MounRiver\MounRiver_Studio2
cmake --preset release
cmake --build --preset release --parallel
```

On POSIX systems, export the installation path before sourcing the activation
script:

```sh
export MRS2_ROOT=/opt/mounriver
. ./scripts/activate.sh
cmake --preset release
cmake --build --preset release --parallel
```

`release` and `debug` are the only public presets, and both live in the tracked
`CMakePresets.json`. The activation script exports `MRS2_ROOT` into the current
shell. CMake reads that environment variable directly and stops at configure
time when it is absent; no `CMakeUserPresets.json` or machine-local preset is
generated. Omit `-MrsRoot` when `MRS2_ROOT` is already present in the shell.

The activation scripts prepend the exact GCC, GDB, and OpenOCD selected by the
imported MRS2 project to the current shell's `PATH`. They do not modify the
global user or system environment. CMake and Ninja should remain unmodified,
upstream installations. Optional generated VS Code tasks use the same two
presets and inherit the activated environment.

Import creates `cmake/application.cmake` with explanatory comments only if it
does not exist. Put application
sources, definitions, libraries, and `add_subdirectory` calls in this file.
It runs after the firmware target has been created:

```cmake
target_sources(${WCH_PROJECT_NAME} PRIVATE app/control.cpp)
target_compile_definitions(${WCH_PROJECT_NAME} PRIVATE APP_FEATURE=1)
```

Running `import` again refreshes generated files, including `CMakeLists.txt`
and `cmake/wch-project.cmake`, from current MRS2 facts. First rebuild in MRS2
to refresh its makefiles. `cmake/application.cmake` is never overwritten, even with
`-Force` / `--force`. Keep customizations there rather than editing generated
files. Existing customizations in generated files must be moved there before
re-importing. Ordinary source edits only need a CMake build, not a re-import.

## Build After Cloning

Commit `CMakeLists.txt`, `CMakePresets.json`, the complete `cmake/` and `scripts/`
directories (including `cmake/application.cmake`), and all required sources,
headers, libraries, and linker scripts. Do not commit `build/` or machine-local
tool paths. Dependencies outside the project must also be made available to
other developers; importing does not copy them into the repository.

`cmake/application.cmake` is shared application build logic, not personal machine
configuration. `CMakePresets.json` holds shared presets and belongs in Git.
Optional `CMakeUserPresets.json` holds personal presets and machine-local settings;
exclude it from Git. The generated activation script supplies `MRS2_ROOT`, so
this personal presets file is not required.

After cloning, another developer does **not** need to run the installer or
importer. Install CMake, Ninja, and MRS2 with the selected toolchain, then run
the activation and build commands above using their own MRS2 installation path.
Normal CMake builds do not need MRS2-generated `obj/` makefiles.

Refreshing MRS2 settings is a separate operation: it requires updated MRS2
makefiles and a local copy of `wch-cmake` (or the release installer). The
installer does not retain the importer in the generated project.

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
& ([scriptblock]::Create((irm https://github.com/guajun/wch-cmake/releases/latest/download/install.ps1))) -Project F:\wch\blink\CH32X035F8U
```

The installer stages the release inside the selected project, verifies its
SHA-256 checksum, imports the four project-local outputs, and removes the
staging directory. It does not install a global `wch-cmake` command or leave
files in the system temporary directory. Pin `-Version v0.1.2` in reproducible
setup. CMake configure never downloads mutable project logic.

## Sources Of Truth

- Before import, MRS2 `.template/.launch` and generated makefiles are bootstrap
  inputs.
- After import, generated `CMakeLists.txt` and `cmake/wch-project.cmake` supply
  the imported build; user-owned `cmake/application.cmake` supplies customizations.
- The current process environment owns the machine-local `MRS2_ROOT` path.
- `.project/.cproject/.wvproj` are not consumed during normal CMake builds.
- `wchlink-cli` owns physical probe sessions and has no build-generation code.

The generated `cmake/wch-import-lock.json` records input hashes so later tooling
can detect an intentional or accidental re-import boundary.
