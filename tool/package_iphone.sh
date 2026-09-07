#!/usr/bin/env bash
set -euo pipefail
app='build/ios/iphoneos/Runner.app'
[[ -d "$app" ]] || { echo 'Compiled iPhone app is missing.' >&2; exit 1; }
[[ -f "$app/Runner" ]] || { echo 'iPhone executable is missing.' >&2; exit 1; }
mkdir -p build/iphone/Payload
ditto "$app" build/iphone/Payload/Runner.app
(
  cd build/iphone
  ditto -c -k --keepParent Payload WingStar-iPhone-unsigned.ipa
  unzip -tq WingStar-iPhone-unsigned.ipa
  shasum -a 256 WingStar-iPhone-unsigned.ipa > SHA256SUMS.txt
)
