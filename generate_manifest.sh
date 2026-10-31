#!/usr/bin/env bash
set -euo pipefail

# Auto-generated manifest update script
# Usage: ./generate_manifest.sh [--version VERSION]

APP_NAME="fastskill"
MANIFEST_FILE="bucket/${APP_NAME}.json"

if ! command -v jq &> /dev/null || ! command -v curl &> /dev/null; then
    echo "Error: jq and curl are required"
    exit 1
fi

# Everything comes from FastSkill's download site, never from GitHub: the source repository is
# private. Set DOWNLOAD_BASE to override.
SITE="${DOWNLOAD_BASE:-https://get.gofastskill.com}"

VERSION="${2:-latest}"

# "latest" is the stable track: /latest/<os>/<arch> redirects to /v/<version>/<file>.
if [ "$VERSION" = "latest" ] || [ -z "$VERSION" ]; then
    LOCATION=$(curl -fsS -o /dev/null -w '%{redirect_url}' "$SITE/latest/windows/x64")
    VERSION=$(printf '%s\n' "$LOCATION" | sed -n 's#^.*/v/\([^/]*\)/.*#\1#p')
    if [ -z "$VERSION" ]; then
        echo "Error: could not resolve the latest version from $SITE/latest/windows/x64"
        exit 1
    fi
else
    VERSION=$(echo "$VERSION" | sed 's/^v//')
fi
RELEASE_TAG="v$VERSION"

if ! CHECKSUMS=$(curl -fsSL "$SITE/v/$VERSION/checksums.txt"); then
    echo "Error: $SITE has no checksums for $VERSION"
    exit 1
fi

# Both Windows builds.
BASE="$SITE/v/$VERSION"
digest_of() {
    printf '%s\n' "$CHECKSUMS" | awk -v n="$1" '$2 == n || $2 == "*" n { print $1; exit }'
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
echo "Hash: $X64_HASH"
