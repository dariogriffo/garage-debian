#!/bin/bash
set -euo pipefail

# Upstream Linux architectures for garage (https://git.deuxfleurs.fr/Deuxfleurs/garage):
#   amd64  -> https://garagehq.deuxfleurs.fr/_releases/<version>/x86_64-unknown-linux-musl/garage
#   arm64  -> https://garagehq.deuxfleurs.fr/_releases/<version>/aarch64-unknown-linux-musl/garage
#   armhf  -> https://garagehq.deuxfleurs.fr/_releases/<version>/armv6l-unknown-linux-musleabihf/garage
#   i386   -> https://garagehq.deuxfleurs.fr/_releases/<version>/i686-unknown-linux-musl/garage
#
# amd64, arm64, armhf and i386 (no Gitea release assets; binaries are published on
# garagehq.deuxfleurs.fr/_releases/. No ppc64el, s390x or riscv64 builds upstream).

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

# Returns the garagehq.deuxfleurs.fr target-triple directory for a given Debian architecture
get_garage_target() {
    local arch=$1
    case "$arch" in
        "amd64")
            echo "x86_64-unknown-linux-musl"
            ;;
        "arm64")
            echo "aarch64-unknown-linux-musl"
            ;;
        "armhf")
            echo "armv6l-unknown-linux-musleabihf"
            ;;
        "i386")
            echo "i686-unknown-linux-musl"
            ;;
        *)
            echo ""
            ;;
    esac
}

# Downloads the garage binary for the given architecture into a local directory
download_binary() {
    local build_arch=$1
    local target

    target=$(get_garage_target "$build_arch")
    if [ -z "$target" ]; then
        echo "❌ Unsupported architecture: $build_arch"
        echo "Supported architectures: amd64, arm64, armhf, i386"
        return 1
    fi

    if [ -f "$build_arch/garage" ]; then
        echo "  Binary for $build_arch already downloaded, skipping."
        return 0
    fi

    mkdir -p "$build_arch"

    local url="https://garagehq.deuxfleurs.fr/_releases/v${garage_VERSION}/${target}/garage"
    echo "  Downloading $url"
    if ! wget -q -O "$build_arch/garage" "$url"; then
        echo "❌ Failed to download garage binary for $build_arch"
        rm -f "$build_arch/garage"
        return 1
    fi
    chmod +x "$build_arch/garage"
}

# Function to build for a specific architecture
build_architecture() {
    local build_arch=$1

    echo "Building for architecture: $build_arch"

    if ! download_binary "$build_arch"; then
        return 1
    fi

    declare -a arr=("bookworm" "trixie" "forky" "sid")

    for dist in "${arr[@]}"; do
        FULL_VERSION="$garage_VERSION-${BUILD_VERSION}~${dist}_${build_arch}"
        echo "  Building $FULL_VERSION"

        if ! docker build . -t "garage-$dist-$build_arch" \
            --build-arg DEBIAN_DIST="$dist" \
            --build-arg garage_VERSION="$garage_VERSION" \
            --build-arg BUILD_VERSION="$BUILD_VERSION" \
            --build-arg FULL_VERSION="$FULL_VERSION" \
            --build-arg ARCH="$build_arch" \
            --build-arg GARAGE_RELEASE="$build_arch"; then
            echo "❌ Failed to build Docker image for $dist on $build_arch"
            return 1
        fi

        id="$(docker create "garage-$dist-$build_arch")"
        if ! docker cp "$id:/garage_$FULL_VERSION.deb" - > "./garage_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb package for $dist on $build_arch"
            return 1
        fi

        if ! tar -xf "./garage_$FULL_VERSION.deb"; then
            echo "❌ Failed to extract .deb contents for $dist on $build_arch"
            return 1
        fi
    done

    # Clean up downloaded binary
    rm -rf "$build_arch" || true

    echo "✅ Successfully built for $build_arch"
    return 0
}

# Main build logic
if [ "$ARCH" = "all" ]; then
    echo "🚀 Building garage $garage_VERSION-$BUILD_VERSION for all supported architectures..."
    echo ""

    # All supported architectures
    ARCHITECTURES=("amd64" "arm64" "armhf" "i386")

    for build_arch in "${ARCHITECTURES[@]}"; do
        echo "==========================================="
        echo "Building for architecture: $build_arch"
        echo "==========================================="

        if ! build_architecture "$build_arch"; then
            echo "❌ Failed to build for $build_arch"
            exit 1
        fi

        echo ""
    done

    echo "🎉 All architectures built successfully!"
    echo "Generated packages:"
    ls -la garage_*.deb
else
    # Build for single architecture
    if ! build_architecture "$ARCH"; then
        exit 1
    fi
fi
