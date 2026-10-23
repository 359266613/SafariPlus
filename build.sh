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
  bash -e get_webkit.sh
fi

echo ">>> Building $SCHEME..."
make package "${MAKE_ARGS[@]}"
echo ">>> Build complete."
