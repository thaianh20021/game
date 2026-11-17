#!/usr/bin/env bash
# Ask the image model for one sheet. Keys come from the environment, never from a file.
# Usage: MK_KEYS="key1 key2 ..." tools/gen.sh <name> "<subject prompt>" "<style prompt>"   -> gen/raw_<name>.png
# (MK_KEY with a single key still works.) On a failed answer it moves on to the next key, then the next model.
# MK_MODELS overrides the models tried, in order. Gemini answers in JPEG; tools/pix.gd reads both.
set -u
B=${MK_URL:-https://thaianhdev.loc.cc}
KEYS=${MK_KEYS:-${MK_KEY:-}}
MODELS=${MK_MODELS:-"ag/gemini-3.1-flash-image gemini/gemini-3.1-flash-image-preview cx/gpt-image-2.5 cx/gpt-image-2.6-flare"}
mkdir -p gen
rm -f gen/raw_$1.png
for model in $MODELS; do
  printf '{"model":"%s","n":1,"size":"1536x1024","prompt":"%s %s"}' "$model" "$2" "$3" > gen/req_$1.json
  for key in $KEYS; do
    curl -s -m 280 $B/v1/images/generations -H "Authorization: Bearer $key" -H "Content-Type: application/json" -d @gen/req_$1.json -o gen/out_$1.json -w "$1 $model key${key: -4} %{http_code} %{size_download}\n"
    if [ "$(stat -c %s gen/out_$1.json)" -gt 10000 ] && grep -q '"b64_json"' gen/out_$1.json; then
      sed 's/.*"b64_json":"\([^"]*\)".*/\1/' gen/out_$1.json | base64 -d > gen/raw_$1.png 2>/dev/null
      if [ -s gen/raw_$1.png ]; then
        rm -f gen/out_$1.json gen/req_$1.json
        exit 0
      fi
    fi
    head -c 160 gen/out_$1.json; echo
    sleep 3
  done
done
rm -f gen/out_$1.json gen/req_$1.json
echo "$1 FAILED"
exit 1
