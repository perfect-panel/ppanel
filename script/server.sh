#!/usr/bin/env bash
# Fetch latest release from GitHub and download/extract platform-specific binaries
# Usage: script/server.sh [--repo owner/repo] [--dest modules] [--dry-run] [--force]

set -euo pipefail

REPO_DEFAULT="perfect-panel/server"
DEST_DIR="modules"
DRY_RUN=0
FORCE=0

# Platforms to download
PLATFORMS=("darwin-amd64" "darwin-arm64" "linux-amd64" "linux-arm64")

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="$2"; shift 2;;
    --dest)
      DEST_DIR="$2"; shift 2;;
    --dry-run)
      DRY_RUN=1; shift;;
    --force)
      FORCE=1; shift;;
    -h|--help)
      cat <<USAGE
Usage: $0 [--repo owner/repo] [--dest modules] [--dry-run] [--force]

Downloads the latest GitHub release for a repo and extracts binaries for:
  darwin-amd64 darwin-arm64 linux-amd64 linux-arm64

Default repo: ${REPO_DEFAULT}
Default dest: ${DEST_DIR}

Options:
  --dry-run   Only list found download URLs without downloading.
  --force     Overwrite existing files in the destination.
USAGE
      exit 0;;
    *)
      echo "Unknown argument: $1" >&2; exit 2;;
  esac
done

REPO="${REPO:-$REPO_DEFAULT}"

# Ensure we have either jq or python3 for JSON parsing (prefer jq)
PARSER=""
if command -v jq >/dev/null 2>&1; then
  PARSER=jq
elif command -v python3 >/dev/null 2>&1; then
  PARSER=python3
elif command -v python >/dev/null 2>&1; then
  PARSER=python
else
  echo "Error: neither jq nor python3/python is installed. Install one to run this script." >&2
  exit 1
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

API_URL="https://api.github.com/repos/${REPO}/releases/latest"

echo "Fetching latest release metadata for ${REPO}..."
RELEASE_JSON="$TMPDIR/release.json"
if ! curl -sSfL "$API_URL" -o "$RELEASE_JSON"; then
  echo "Failed to fetch release metadata from ${API_URL}" >&2
  exit 1
fi

# Helper: find asset by platform substring (case-insensitive)
find_asset() {
  platform_lc="$1"
  if [[ "$PARSER" == "jq" ]]; then
    # Return as: url||name
    jq -r --arg p "$platform_lc" '.assets[] | select((.name|ascii_downcase) | contains($p)) | (.browser_download_url + "||" + .name)' "$RELEASE_JSON" | head -n1 || true
  else
    "$PARSER" "$RELEASE_JSON" "$platform_lc" - <<PY
import json,sys
f=sys.argv[1]
p=sys.argv[2]
try:
    data=json.load(open(f))
except Exception as e:
    sys.exit(1)
for a in data.get('assets',[]):
    n=a.get('name','').lower()
    if p in n:
        print(a.get('browser_download_url') + '||' + a.get('name'))
        sys.exit(0)
# no match -> exit non-zero
sys.exit(2)
PY
  fi
}

mkdir -p "$DEST_DIR"

echo "Looking for assets for platforms: ${PLATFORMS[*]}"
FOUND=0
for p in "${PLATFORMS[@]}"; do
  echo "- Searching for asset containing: $p"
  asset_line=""
  # call find_asset but tolerate non-zero exit
  if asset_line=$(find_asset "$p" 2>/dev/null) ; then
    :
  else
    asset_line=""
  fi

  if [[ -z "$asset_line" ]]; then
    echo "  No asset found for $p"
    continue
  fi

  FOUND=1
  url=${asset_line%%||*}
  fname=${asset_line#*||}
  echo "  Found: $fname"
  echo "  Download URL: $url"

  if [[ $DRY_RUN -eq 1 ]]; then
    echo "  (dry-run) skipping download for $fname"
    continue
  fi

  outpath="$TMPDIR/$fname"
  echo "  Downloading to $outpath..."
  if ! curl -L --fail --progress-bar -o "$outpath" "$url"; then
    echo "  Download failed for $url" >&2
    continue
  fi
  # create per-platform target dir to avoid overwriting
  target_dir="$DEST_DIR/$p"
  mkdir -p "$target_dir"

  # Determine extraction strategy based on filename (prefer suffix checks to avoid file(1) mis-detection)
  lower="$(echo "$fname" | tr '[:upper:]' '[:lower:]')"
  echo "  Extracting $fname to ${target_dir}..."
  if [[ "$lower" == *.zip ]]; then
    unzip -o "$outpath" -d "$target_dir"
  elif [[ "$lower" == *.tar.gz ]] || [[ "$lower" == *.tgz ]]; then
    tar -xzf "$outpath" -C "$target_dir"
  elif [[ "$lower" == *.tar.xz ]]; then
    tar -xJf "$outpath" -C "$target_dir"
  elif [[ "$lower" == *.gz ]] && [[ ! "$lower" == *.tar.gz ]]; then
    # single-file gz (not tar.gz)
    base="${fname%.*}"
    gunzip -c "$outpath" > "$target_dir/$base"
    chmod +x "$target_dir/$base" || true
  else
    # Fallback: try tar then unzip then treat as a single binary
    if tar -tf "$outpath" >/dev/null 2>&1; then
      tar -xf "$outpath" -C "$target_dir"
    elif unzip -l "$outpath" >/dev/null 2>&1; then
      unzip -o "$outpath" -d "$target_dir"
    else
      target_name="$target_dir/$fname"
      if [[ -f "$target_name" && $FORCE -ne 1 ]]; then
        echo "  File $target_name exists; use --force to overwrite. Skipping.";
      else
        mv -f "$outpath" "$target_name"
        chmod +x "$target_name" || true
      fi
    fi
  fi

  echo "  Done with $fname"
done

if [[ $FOUND -eq 0 ]]; then
  echo "No matching assets were found in the latest release for ${REPO}." >&2
  exit 2
fi

echo "All done. Extracted files are in: ${DEST_DIR}"
