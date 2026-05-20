#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT_DIR="${OUT_DIR:-$ROOT/dist}"
GO_VERSION_INFO="$(go version 2>/dev/null || true)"
mkdir -p "$OUT_DIR"

build_one() {
  local goos="$1" goarch="$2" goarm="${3:-}" gomips="${4:-}"
  local key="${goos}-${goarch}${goarm}${gomips}"
  local name
  name="$(jq -r --arg key "$key" '.[$key].friendlyName // empty' "$ROOT/.github/build/friendly-filenames.json")"
  if [[ -z "$name" ]]; then
    echo "No friendly name for $key" >&2
    return 1
  fi

  local work="$OUT_DIR/work-$name"
  rm -rf "$work"
  mkdir -p "$work"

  echo "==> Building XrayR-$name.zip ($goos/$goarch ${goarm:+GOARM=$goarm} ${gomips:+GOMIPS=$gomips})"
  (
    cd "$ROOT"
    env GOOS="$goos" GOARCH="$goarch" GOARM="$goarm" GOMIPS="$gomips" CGO_ENABLED=0 \
      go build -v -o "$work/XrayR" -trimpath -ldflags "-s -w -buildid="
    if [[ "$goarch" == "mips" || "$goarch" == "mipsle" ]]; then
      env GOOS="$goos" GOARCH="$goarch" GOARM="$goarm" GOMIPS=softfloat CGO_ENABLED=0 \
        go build -v -o "$work/XrayR_softfloat" -trimpath -ldflags "-s -w -buildid="
    fi
  )

  if [[ "$goos" == "windows" ]]; then
    mv "$work/XrayR" "$work/XrayR.exe"
  fi

  cp "$ROOT/README.md" "$work/README.md"
  cp "$ROOT/LICENSE" "$work/LICENSE"
  cp "$ROOT/release/config/dns.json" "$work/dns.json"
  cp "$ROOT/release/config/route.json" "$work/route.json"
  cp "$ROOT/release/config/custom_outbound.json" "$work/custom_outbound.json"
  cp "$ROOT/release/config/custom_inbound.json" "$work/custom_inbound.json"
  cp "$ROOT/release/config/rulelist" "$work/rulelist"
  cp "$ROOT/release/config/config.yml.example" "$work/config.yml"

  local items=("geoip geoip geoip" "domain-list-community dlc geosite")
  for item in "${items[@]}"; do
    read -r repo branch filebase <<<"$item"
    local url="https://raw.githubusercontent.com/v2fly/${repo}/release/${branch}.dat"
    local file="$work/${filebase}.dat"
    echo "Downloading $url"
    curl -fsSL --retry 3 "$url" -o "$file"
    local expected actual
    expected="$(curl -fsSL --retry 3 "$url.sha256sum" | awk '{print $1}')"
    actual="$(shasum -a 256 "$file" | awk '{print $1}')"
    [[ "$expected" == "$actual" ]] || { echo "sha256 mismatch for $filebase.dat" >&2; exit 1; }
  done

  (cd "$work" && touch -mt "$(date +%Y01010000)" *)
  local zipfile="$OUT_DIR/XrayR-$name.zip"
  rm -f "$zipfile" "$zipfile.dgst"
  (cd "$work" && zip -9vr "$zipfile" .)
  for method in md5 sha1 sha256 sha512; do
    openssl dgst -"$method" "$zipfile" | sed 's/([^)]*)//g' >> "$zipfile.dgst"
  done
  echo "Created $zipfile"
}

if [[ $# -eq 0 ]]; then
  cat >&2 <<USAGE
Usage:
  $0 <goos> <goarch> [goarm] [gomips]
Examples:
  $0 linux amd64
  $0 linux arm64
  $0 linux arm 7
  $0 windows amd64
Output: $OUT_DIR
$GO_VERSION_INFO
USAGE
  exit 2
fi

build_one "$@"
