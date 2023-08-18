#!/bin/sh

set -Eeu

# Path to Flutter SDK
export FLUTTER_SDK=/opt/flutter-elinux/flutter

export PATH=$PATH:${FLUTTER_SDK}/bin

# Package name of the build target Flutter app
export APP_PACKAGE_NAME=counter

# The build data.
export RESULT_DIR=build/elinux/arm64
export BUILD_MODE=debug

mkdir -p .dart_tool/flutter_build/flutter-embedded-linux
mkdir -p ${RESULT_DIR}/${BUILD_MODE}/bundle/lib/
mkdir -p ${RESULT_DIR}/${BUILD_MODE}/bundle/data/

# Build Flutter assets.
flutter-elinux build bundle --asset-dir=${RESULT_DIR}/${BUILD_MODE}/bundle/data/flutter_assets
cp ${FLUTTER_SDK}/bin/cache/artifacts/engine/linux-arm64/icudtl.dat \
   ${RESULT_DIR}/${BUILD_MODE}/bundle/data/

# Build kernel_snapshot.
${FLUTTER_SDK}/bin/cache/dart-sdk/bin/dart \
  --verbose \
  --disable-dart-dev ${FLUTTER_SDK}/bin/cache/artifacts/engine/linux-arm64/frontend_server.dart.snapshot \
  --sdk-root ${FLUTTER_SDK}/bin/cache/artifacts/engine/common/flutter_patched_sdk_product/ \
  --target=flutter \
  --no-print-incremental-dependencies \
  -Ddart.vm.profile=false \
  -Ddart.vm.product=true \
  --aot \
  --tfa \
  --packages .dart_tool/package_config.json \
  --output-dill .dart_tool/flutter_build/flutter-embedded-linux/app.dill \
  --depfile .dart_tool/flutter_build/flutter-embedded-linux/kernel_snapshot.d \
  package:${APP_PACKAGE_NAME}/main.dart

# Build AOT image.
${FLUTTER_SDK}/bin/cache/artifacts/engine/linux-arm64/gen_snapshot \
  --deterministic \
  --snapshot_kind=app-aot-elf \
  --elf=.dart_tool/flutter_build/flutter-embedded-linux/libapp.so \
  .dart_tool/flutter_build/flutter-embedded-linux/app.dill
#  --strip

cp .dart_tool/flutter_build/flutter-embedded-linux/libapp.so ${RESULT_DIR}/${BUILD_MODE}/bundle/lib/

