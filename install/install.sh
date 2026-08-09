#!/usr/bin/env sh
set -eu

version=latest
project=
with_vscode=OFF

while [ "$#" -gt 0 ]; do
    case "$1" in
        --version) version=$2; shift 2 ;;
        --project) project=$2; shift 2 ;;
        --with-vscode) with_vscode=ON; shift ;;
        *) echo "unknown argument: $1" >&2; exit 2 ;;
    esac
done

if [ -z "$project" ]; then
    echo "--project is required" >&2
    exit 2
fi
project=$(CDPATH= cd -- "$project" && pwd)

repository=guajun/wch-cmake
if [ "$version" = latest ]; then
    base="https://github.com/$repository/releases/latest/download"
else
    base="https://github.com/$repository/releases/download/$version"
fi

staging=$(mktemp -d "$project/.wch-cmake-install.XXXXXX")
trap 'rm -rf "$staging"' EXIT HUP INT TERM
curl -fsSL "$base/wch-cmake.zip" -o "$staging/wch-cmake.zip"
curl -fsSL "$base/checksums.txt" -o "$staging/checksums.txt"
(cd "$staging" && sha256sum -c checksums.txt)
unzip -q "$staging/wch-cmake.zip" -d "$staging"
chmod +x "$staging/wch-cmake/wch-cmake.sh"

if [ "$with_vscode" = ON ]; then
    "$staging/wch-cmake/wch-cmake.sh" import --project "$project" --with-vscode
else
    "$staging/wch-cmake/wch-cmake.sh" import --project "$project"
fi
echo "Imported wch-cmake $version into $project"
