#!/bin/bash
# 本地打包脚本（需要 macOS + Xcode + 已登录的 Apple ID）
# 用法：./build.sh TEAM_ID   例：./build.sh A1B2C3D4E5
set -euo pipefail

TEAM_ID="${1:-}"
if [ -z "$TEAM_ID" ] || [ ${#TEAM_ID} -ne 10 ]; then
  echo "请传入 10 位 Team ID，例如：./build.sh A1B2C3D4E5"
  echo "Team ID 在 Xcode › Settings › Accounts 里，或在 Apple Developer 后台（免费账号也能拿到）"
  exit 1
fi

cd "$(dirname "$0")"
rm -rf build

xcodebuild \
  -project IslandLyric.xcodeproj \
  -scheme IslandLyric \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath build/IslandLyric.xcarchive \
  -allowProvisioningUpdates \
  -allowProvisioningDeviceRegistration \
  DEVELOPMENT_TEAM="$TEAM_ID" \
  CODE_SIGN_STYLE=Automatic \
  archive

xcodebuild -exportArchive \
  -archivePath build/IslandLyric.xcarchive \
  -exportPath build/export \
  -exportOptionsPlist exportOptions.plist \
  -allowProvisioningUpdates

echo ""
echo "完成：build/export/IslandLyric.ipa"
