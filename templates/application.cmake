# Application build configuration: maintained by the project authors.
# Commit this file to Git. Re-import never overwrites it, even with --force.
# Add sources, definitions, libraries, or subdirectories here after the firmware
# target ${WCH_PROJECT_NAME} has been created.
#
# cmake/wch-project.cmake contains generated MRS2 settings. Re-import replaces
# that file; keep your application customizations here instead.
#
# CMakePresets.json contains shared configure/build presets and belongs in Git.
# Optional CMakeUserPresets.json contains personal presets and machine-local
# settings: keep it out of Git. It is not an application build configuration file.
# The activation script already supplies your local MRS2_ROOT without that file.
#
# Examples:
# target_sources(${WCH_PROJECT_NAME} PRIVATE app/control.cpp)
# target_compile_definitions(${WCH_PROJECT_NAME} PRIVATE APP_FEATURE=1)
