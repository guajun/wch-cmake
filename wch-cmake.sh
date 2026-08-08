#!/usr/bin/env sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
command=${1:-help}
if [ "$#" -gt 0 ]; then
    shift
fi

project=.
build_dir=obj
mrs_root=${MRS2_ROOT:-}
mrs_build=obj
cmake_build=build/local-release
force=OFF

while [ "$#" -gt 0 ]; do
    case "$1" in
        --project) project=$2; shift 2 ;;
        --build-dir) build_dir=$2; shift 2 ;;
        --mrs-root) mrs_root=$2; shift 2 ;;
        --mrs-build) mrs_build=$2; shift 2 ;;
        --cmake-build) cmake_build=$2; shift 2 ;;
        --force) force=ON; shift ;;
        -h|--help) command=help; shift ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done

case "$command" in
    import)
        [ -n "$mrs_root" ] || {
            echo "MRS2_ROOT or --mrs-root is required on this platform" >&2
            exit 2
        }
        exec cmake "-DWCH_PROJECT=$project" "-DWCH_BUILD_DIR=$build_dir" \
            "-DMRS2_ROOT=$mrs_root" "-DWCH_FORCE=$force" \
            -P "$script_dir/scripts/import.cmake"
        ;;
    verify)
        [ -n "$mrs_root" ] || {
            echo "MRS2_ROOT or --mrs-root is required on this platform" >&2
            exit 2
        }
        exec cmake "-DWCH_PROJECT=$project" "-DWCH_MRS_BUILD=$mrs_build" \
            "-DWCH_CMAKE_BUILD=$cmake_build" "-DMRS2_ROOT=$mrs_root" \
            -P "$script_dir/scripts/verify.cmake"
        ;;
    help)
        echo "Usage:"
        echo "  ./wch-cmake.sh import --project PATH [--build-dir obj] [--mrs-root PATH] [--force]"
        echo "  ./wch-cmake.sh verify --project PATH [--mrs-build obj] [--cmake-build build/local-release]"
        ;;
    *)
        echo "unknown command: $command" >&2
        exit 2
        ;;
esac
