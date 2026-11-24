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
# compiler errors also go out as GitHub annotations (readable without log access)
annotate() { grep -E "error:|Error " "$1" | head -15 | sed 's/^/::error::/' ; }
(cd godot-cpp && scons platform=ios arch=arm64 target=template_release -j"$jobs") > cpp.log 2>&1 || { tail -40 cpp.log; annotate cpp.log; exit 1; }
tail -3 cpp.log
scons platform=ios arch=arm64 target=template_release -j"$jobs" > sk.log 2>&1 || { cat sk.log | tail -60; annotate sk.log; exit 1; }
cat sk.log | tail -5

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
