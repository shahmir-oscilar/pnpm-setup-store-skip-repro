#!/usr/bin/env bash
# Records the entries pnpm/setup fingerprints (src/store-fingerprint) and prints
# the ones that changed since the previous call.
set -euo pipefail

label="$1"
store="$(pnpm store path)"
out="$RUNNER_TEMP/fingerprint-$label"

{
  for entry in index.db index.db-wal; do
    if [ -e "$store/$entry" ]; then
      echo "$entry $(find "$store/$entry" -maxdepth 0 -printf '%s %T@')"
    else
      echo "$entry none"
    fi
  done
  find "$store/files" -mindepth 1 -maxdepth 1 -printf 'files/%f %s %T@\n' | sort
} > "$out"

echo "store: $store ($(wc -l < "$out") entries)"
previous="$(cat "$RUNNER_TEMP/fingerprint-last" 2>/dev/null || true)"
if [ -n "$previous" ]; then
  changed="$(diff "$RUNNER_TEMP/fingerprint-$previous" "$out" | grep -c '^>' || true)"
  echo "changed since '$previous': $changed"
  diff "$RUNNER_TEMP/fingerprint-$previous" "$out" | head -20 || true
fi
echo "$label" > "$RUNNER_TEMP/fingerprint-last"
