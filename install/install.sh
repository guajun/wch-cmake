#!/usr/bin/env sh
set -eu

version=latest
project=
install_directory=${XDG_DATA_HOME:-"$HOME/.local/share"}/wch-cmake

while [ "$#" -gt 0 ]; do
    case "$1" in
        --version) version=$2; shift 2 ;;
        --project) project=$2; shift 2 ;;
        --install-directory) install_directory=$2; shift 2 ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done

repository=guajun/wch-cmake
if [ "$version" = latest ]; then
    base="https://github.com/$repository/releases/latest/download"
else
    base="https://github.com/$repository/releases/download/$version"
fi

temporary=$(mktemp -d)
trap 'rm -rf "$temporary"' EXIT HUP INT TERM
curl -fsSL "$base/wch-cmake.zip" -o "$temporary/wch-cmake.zip"
curl -fsSL "$base/checksums.txt" -o "$temporary/checksums.txt"
(cd "$temporary" && sha256sum -c checksums.txt)
unzip -q "$temporary/wch-cmake.zip" -d "$temporary"
mkdir -p "$install_directory"
cp -R "$temporary/wch-cmake/." "$install_directory/"
chmod +x "$install_directory/wch-cmake.sh"
echo "Installed wch-cmake scripts at $install_directory"

if [ -n "$project" ]; then
    "$install_directory/wch-cmake.sh" import --project "$project"
fi
