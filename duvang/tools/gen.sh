#!/usr/bin/env bash
# Ask the image model for one sheet. The key comes from the environment, never from a file.
# Usage: DV_KEY=... tools/gen.sh <name> "<subject prompt>" "<style prompt>"   -> gen/raw_<name>.png
set -u
B=${DV_URL:-https://thaianhdev.loc.cc}
mkdir -p gen
printf '{"model":"cx/gpt-image-2.5","n":1,"size":"1536x1024","prompt":"%s %s"}' "$2" "$3" > gen/req_$1.json
for try in 1 2 3; do
  curl -s -m 280 $B/v1/images/generations -H "Authorization: Bearer $DV_KEY" -H "Content-Type: application/json" -d @gen/req_$1.json -o gen/out_$1.json -w "$1 try$try %{http_code} %{size_download}\n"
  if [ "$(stat -c %s gen/out_$1.json)" -gt 10000 ]; then break; fi
  head -c 200 gen/out_$1.json; echo; sleep 10
done
sed 's/.*"b64_json":"\([^"]*\)".*/\1/' gen/out_$1.json | base64 -d > gen/raw_$1.png
rm -f gen/out_$1.json gen/req_$1.json
