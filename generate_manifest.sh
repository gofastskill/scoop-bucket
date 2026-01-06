#!/usr/bin/env bash
set -euo pipefail

# Auto-generated manifest update script
# Usage: ./generate_manifest.sh [--version VERSION]

APP_NAME="fastskill"
GITHUB_REPO="gofastskill/fastskill"
MANIFEST_FILE="bucket/${APP_NAME}.json"

# Check dependencies
check_dependencies() {
    if ! command -v gh &> /dev/null; then
        echo "Error: GitHub CLI (gh) is not installed"
        exit 1
    fi

    if ! gh auth status &> /dev/null; then
        echo "Error: GitHub CLI (gh) is not authenticated"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        echo "Error: jq is not installed"
        exit 1
    fi
}

check_dependencies

VERSION="${2:-latest}"

# Get version and release tag
if [ "$VERSION" = "latest" ] || [ -z "$VERSION" ]; then
    RELEASE_TAG=$(gh release view --repo "$GITHUB_REPO" --json tagName -q .tagName)
    VERSION=$(echo "$RELEASE_TAG" | sed 's/^v//')
else
    VERSION=$(echo "$VERSION" | sed 's/^v//')
    RELEASE_TAG="v$VERSION"
fi

# Get release data
RELEASE_DATA=$(gh api "repos/$GITHUB_REPO/releases/tags/$RELEASE_TAG")

# Extract Windows asset URL and hash
WINDOWS_ASSET=$(echo "$RELEASE_DATA" | jq -r '.assets[] | select(.name | contains("windows")) | select(.name | contains("msvc"))')

if [ -z "$WINDOWS_ASSET" ] || [ "$WINDOWS_ASSET" = "null" ]; then
    echo "⚠️  Warning: Windows binary not found in release $RELEASE_TAG"
    echo "Skipping Scoop manifest update"
    exit 0
fi

WINDOWS_URL=$(echo "$WINDOWS_ASSET" | jq -r '.browser_download_url // empty')
if [ -z "$WINDOWS_URL" ] || [ "$WINDOWS_URL" = "null" ]; then
    # Construct URL from release tag
    WINDOWS_URL="https://github.com/$GITHUB_REPO/releases/download/$RELEASE_TAG/fastskill-x86_64-pc-windows-msvc.zip"
fi

WINDOWS_HASH=$(echo "$WINDOWS_ASSET" | jq -r '.digest' | sed 's/sha256://')
if [ -z "$WINDOWS_HASH" ] || [ "$WINDOWS_HASH" = "null" ]; then
    echo "Error: Could not find SHA256 digest for Windows binary"
    exit 1
fi

# Update manifest using jq
jq --arg version "$VERSION" \
   --arg url "$WINDOWS_URL" \
   --arg hash "$WINDOWS_HASH" \
   '.version = $version | .architecture."64bit".url = $url | .architecture."64bit".hash = $hash' \
   "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp" && mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"

echo "✅ Scoop manifest updated: $MANIFEST_FILE"
echo "Version: $VERSION"
echo "URL: $WINDOWS_URL"
echo "Hash: $WINDOWS_HASH"
