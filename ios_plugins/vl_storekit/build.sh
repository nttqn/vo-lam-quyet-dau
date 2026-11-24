#!/bin/bash
# Builds the VLStoreKit GDExtension (StoreKit IAP) for iOS and installs it
# into addons/vl_storekit/ (gitignored). macOS + Xcode only: run by
# .github/workflows/ios.yml before the Godot import/export.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
root="$(cd "$here/../.." && pwd)"
cd "$here"

command -v scons >/dev/null || brew install scons
[ -d godot-cpp ] || git clone --depth 1 --branch godot-4.5-stable https://github.com/godotengine/godot-cpp

jobs=$(sysctl -n hw.ncpu)
(cd godot-cpp && scons platform=ios arch=arm64 target=template_release -j"$jobs")
scons platform=ios arch=arm64 target=template_release -j"$jobs"

lib_cpp=$(ls godot-cpp/bin/libgodot-cpp.ios.template_release.arm64.a)
lib_sk=$(ls bin/libvlstorekit*.a | head -1)
rm -rf build && mkdir -p build
libtool -static -o build/libvlstorekit.a "$lib_sk" "$lib_cpp"
nm -g build/libvlstorekit.a 2>/dev/null | grep -q " T _vl_storekit_init" || { echo "entry symbol missing"; exit 1; }

out="$root/addons/vl_storekit"
rm -rf "$out" && mkdir -p "$out"
xcodebuild -create-xcframework -library build/libvlstorekit.a -output "$out/vlstorekit.xcframework"
cp vl_storekit.gdextension.in "$out/vl_storekit.gdextension"
ls -R "$out"
