#!/bin/bash
set -euo pipefail

# Upstream Linux architectures for garage (https://git.deuxfleurs.fr/Deuxfleurs/garage):
#   amd64  -> https://garagehq.deuxfleurs.fr/_releases/<version>/x86_64-unknown-linux-musl/garage
#   arm64  -> https://garagehq.deuxfleurs.fr/_releases/<version>/aarch64-unknown-linux-musl/garage
#   armhf  -> https://garagehq.deuxfleurs.fr/_releases/<version>/armv6l-unknown-linux-musleabihf/garage
#   i386   -> https://garagehq.deuxfleurs.fr/_releases/<version>/i686-unknown-linux-musl/garage
#
# amd64, arm64, armhf and i386 (no Gitea release assets; binaries are published on garagehq.deuxfleurs.fr/_releases/. No ppc64el, s390x or riscv64 builds upstream).
# TODO: implement garage build

garage_VERSION=$1
BUILD_VERSION=$2
ARCH=${3:-amd64}  # Default to amd64 if no architecture specified

if [ -z "$garage_VERSION" ] || [ -z "$BUILD_VERSION" ]; then
    echo "Usage: $0 <garage_version> <build_version> [architecture]"
    echo "Example: $0 1.2.3 1 arm64"
    echo "Example: $0 1.2.3 1 all    # Build for all architectures"
    echo "Supported architectures: amd64, arm64, armhf, i386, all"
    exit 1
fi

echo "build_ubuntu.sh for garage is not implemented yet."
exit 1
