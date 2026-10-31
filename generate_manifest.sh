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

# Both Windows builds. Downloads come from FastSkill's download site, never from GitHub: the
# source repository is private. Set DOWNLOAD_BASE to override.
BASE="${DOWNLOAD_BASE:-https://get.gofastskill.com}/v/$VERSION"
digest_of() {
    echo "$RELEASE_DATA" | jq -r --arg n "$1" '.assets[] | select(.name == $n) | .digest // empty' | sed 's/sha256://'
}
X64=fastskill-x86_64-pc-windows-msvc.zip
ARM64=fastskill-aarch64-pc-windows-msvc.zip
X64_HASH=$(digest_of "$X64")
ARM64_HASH=$(digest_of "$ARM64")
if [ -z "$X64_HASH" ]; then
    echo "⚠️  Warning: $X64 not found in release $RELEASE_TAG"
    echo "Skipping Scoop manifest update"
    exit 0
fi
WINDOWS_URL="$BASE/$X64"

jq --arg version "$VERSION" \
   --arg base "$BASE" --arg x64 "$X64" --arg x64h "$X64_HASH" \
   --arg arm "$ARM64" --arg armh "$ARM64_HASH" \
   '.version = $version
    | .architecture."64bit" = {url: ($base + "/" + $x64), hash: $x64h}
    | if $armh != "" then .architecture.arm64 = {url: ($base + "/" + $arm), hash: $armh} else del(.architecture.arm64) end' \
   "$MANIFEST_FILE" > "$MANIFEST_FILE.tmp" && mv "$MANIFEST_FILE.tmp" "$MANIFEST_FILE"

echo "✅ Scoop manifest updated: $MANIFEST_FILE"
echo "Version: $VERSION"
echo "URL: $WINDOWS_URL"
echo "Hash: $WINDOWS_HASH"
