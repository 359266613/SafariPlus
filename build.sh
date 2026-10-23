#!/bin/bash
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"
: "${THEOS:?Set THEOS to your Theos installation directory}"

SDK_VERSION="${IOS_SDK_VERSION:-16.5}"
SCHEME="${THEOS_PACKAGE_SCHEME:-rootless}"
if [[ "$SCHEME" != "rootless" && "$SCHEME" != "roothide" ]]; then
  echo "Unsupported package scheme: $SCHEME" >&2
  exit 1
fi
if [[ ! -d "$THEOS/sdks/iPhoneOS${SDK_VERSION}.sdk" ]]; then
  echo "Missing SDK: $THEOS/sdks/iPhoneOS${SDK_VERSION}.sdk" >&2
  exit 1
fi

# Command-line variables override the upstream Makefile and reach subprojects.
MAKE_ARGS=(
  "THEOS_PACKAGE_SCHEME=$SCHEME"
  "ROOTLESS=1"
  "TARGET=iphone:clang:${SDK_VERSION}:15.0"
  "ARCHS=arm64 arm64e"
)

echo ">>> Cleaning..."
make clean "${MAKE_ARGS[@]}"

if [[ ! -f .WebKit/usr/local/include/WebCore/HTMLMediaElement.h ||
      ! -f .WebKit/usr/local/include/wtf/RefPtr.h ]]; then
  echo ">>> Preparing patched WebKit headers..."
  WEBKIT_TEMP="$(mktemp -d)"
  trap 'rm -rf "$WEBKIT_TEMP"' EXIT
  ARCHIVE="$WEBKIT_TEMP/WebKit.zip"
  if [[ -n "${WEBKIT_ARCHIVE_PATH:-}" ]]; then
    cp "$WEBKIT_ARCHIVE_PATH" "$ARCHIVE"
  else
    # Keep the upstream revision: newer WebKit headers are not interchangeable.
    WEBKIT_URL="${WEBKIT_ARCHIVE_URL:-https://s3-us-west-2.amazonaws.com/minified-archives.webkit.org/ios-simulator-14-x86_64-release/274758.zip}"
    if ! curl --fail --location --retry 3 --connect-timeout 30 \
        --output "$ARCHIVE" "$WEBKIT_URL"; then
      echo "WebKit download failed. The upstream archive may return HTTP 403." >&2
      echo "Set WEBKIT_ARCHIVE_URL to a trusted mirror of revision 274758," >&2
      echo "or WEBKIT_ARCHIVE_PATH to a local copy of the original ZIP." >&2
      exit 1
    fi
  fi
  if ! unzip -tq "$ARCHIVE"; then
    echo "WebKit archive is not a valid ZIP. No headers were installed." >&2
    exit 1
  fi
  unzip -q "$ARCHIVE" -d "$WEBKIT_TEMP/extracted"
  WEBKIT_RELEASE="$WEBKIT_TEMP/extracted/Release-iphonesimulator"
  if [[ ! -f "$WEBKIT_RELEASE/usr/local/include/WebCore/HTMLMediaElement.h" ||
        ! -f "$WEBKIT_RELEASE/usr/local/include/wtf/RefPtr.h" ]]; then
    echo "Expected the original revision 274758 ZIP with Release-iphonesimulator headers." >&2
    exit 1
  fi
  mkdir -p .WebKit
  cp -R "$WEBKIT_RELEASE/." .WebKit/
fi

# Apply the same compatibility patches as upstream get_webkit.sh, also to
# preinstalled headers. Do not run its download step: it accepts HTTP errors.
rm -rf .WebKit/WebKit.framework .WebKit/WebKitLegacy.framework
REFPTR=".WebKit/usr/local/include/wtf/RefPtr.h"
PATCHED_REFPTR='ALWAYS_INLINE ~RefPtr() { m_ptr = nullptr; } ALWAYS_INLINE typename PtrTraits::StorageType ptr() { return m_ptr; }'
if ! grep -Fq "$PATCHED_REFPTR" "$REFPTR"; then
  ORIGINAL_REFPTR='ALWAYS_INLINE ~RefPtr() { RefDerefTraits::derefIfNotNull(PtrTraits::exchange(m_ptr, nullptr)); }'
  if ! grep -Fq "$ORIGINAL_REFPTR" "$REFPTR"; then
    echo "Unsupported WebKit RefPtr.h: use the compatible revision 274758 headers." >&2
    exit 1
  fi
  sed -e "s|$ORIGINAL_REFPTR|$PATCHED_REFPTR|" "$REFPTR" > "${REFPTR}.patched"
  mv "${REFPTR}.patched" "$REFPTR"
  grep -Fq "$PATCHED_REFPTR" "$REFPTR"
fi

echo ">>> Building $SCHEME..."
make package "${MAKE_ARGS[@]}"
echo ">>> Build complete."
