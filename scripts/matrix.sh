#!/usr/bin/env bash
set -euo pipefail

MIN_GDAL="${MIN_GDAL:?set MIN_GDAL, e.g. 3.6}"
REPO="osgeo/gdal"
PAGE_SIZE=1000

TOKEN=$(curl -fsSL "https://ghcr.io/token?scope=repository:${REPO}:pull&service=ghcr.io" | jq -r .token)
RESPONSE=$(curl -fsSL -H "Authorization: Bearer ${TOKEN}" "https://ghcr.io/v2/${REPO}/tags/list?n=${PAGE_SIZE}")

COUNT=$(echo "$RESPONSE" | jq '.tags | length')
if [ "$COUNT" -ge "$PAGE_SIZE" ]; then
  echo "matrix.sh: WARNING got $COUNT tags (page size $PAGE_SIZE) -- list may be truncated, bump PAGE_SIZE in this script" >&2
fi

echo "$RESPONSE" | jq -c --arg min "$MIN_GDAL" '
  ($min | split(".") | map(tonumber)) as $min_parts
  | [ .tags[]
      | select(test("^ubuntu-full-[0-9]+\\.[0-9]+\\.[0-9]+$"))
      | capture("^ubuntu-full-(?<version>[0-9]+\\.[0-9]+\\.[0-9]+)$")
      | . + {parts: (.version | split(".") | map(tonumber))}
    ]
  | group_by([.parts[0], .parts[1]])
  | map(max_by(.parts[2]))
  | map(select(.parts[0:2] >= $min_parts))
  | (max_by(.parts)) as $newest
  | map({gdal_version: .version, is_latest: (. == $newest)})
  | sort_by(.gdal_version | split(".") | map(tonumber))
'
