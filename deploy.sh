#!/usr/bin/env bash
set -euo pipefail

bucket="${1:-geode-rtracker}"
base_url="https://${bucket}.s3.amazonaws.com"

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required." >&2
  exit 1
fi

if ! command -v md5sum >/dev/null 2>&1; then
  echo "md5sum is required." >&2
  exit 1
fi

if ! command -v file >/dev/null 2>&1; then
  echo "file is required." >&2
  exit 1
fi

mapfile -t files < <(find . -maxdepth 1 -type f -printf '%P\n' | sort)

filtered_files=()
for file_path in "${files[@]}"; do
  case "$file_path" in
    ""|"deploy.sh")
      continue
      ;;
  esac
  filtered_files+=("$file_path")
done

diff_files=()

etag_for() {
  local url="$1"
  local headers http_code
  headers=$(mktemp)
  http_code=$(curl -sS -I -o "$headers" -w '%{http_code}' "$url")
  if [ "$http_code" != "200" ]; then
    rm -f "$headers"
    echo ""
    return
  fi
  awk -F'"' 'tolower($0) ~ /^etag:/ {gsub(/\r/, "", $2); print $2}' "$headers"
  rm -f "$headers"
}

for file_path in "${filtered_files[@]}"; do
  remote_etag=$(etag_for "${base_url}/${file_path}")
  local_md5=$(md5sum "$file_path" | awk '{print $1}')
  if [ -z "$remote_etag" ] || [ "$remote_etag" != "$local_md5" ]; then
    diff_files+=("$file_path")
  fi
done

if [ "${#diff_files[@]}" -eq 0 ]; then
  echo "No changes to deploy."
  exit 0
fi

echo "Changed files:"
for file_path in "${diff_files[@]}"; do
  echo "- ${file_path}"
done

echo ""
read -r -p "Back up remote files before uploading? [y/N] " response
if [[ "$response" =~ ^[Yy]$ ]]; then
  timestamp=$(date -u +%Y%m%d-%H%M%S)
  echo "Creating backups under backup/${timestamp}/"
  for file_path in "${diff_files[@]}"; do
    tmp_file=$(mktemp)
    if curl -fsS -o "$tmp_file" "${base_url}/${file_path}"; then
      content_type=$(file --mime-type -b "$file_path")
      curl -sS -X PUT --upload-file "$tmp_file" -H "Content-Type: ${content_type}" \
        "${base_url}/backup/${timestamp}/${file_path}"
    else
      echo "Skipping backup for ${file_path} (remote file not found)."
    fi
    rm -f "$tmp_file"
  done
fi

echo "Uploading changed files..."
for file_path in "${diff_files[@]}"; do
  content_type=$(file --mime-type -b "$file_path")
  curl -sS -X PUT --upload-file "$file_path" -H "Content-Type: ${content_type}" \
    "${base_url}/${file_path}"
  echo "Uploaded ${file_path}"
done
