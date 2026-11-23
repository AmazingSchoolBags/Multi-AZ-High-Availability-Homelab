#!/usr/bin/env bash
set -euo pipefail

if (( $# != 2 )); then
  printf 'Usage: %s {flask|patroni|vikunja} BASE_URL\n' "${0##*/}" >&2
  exit 2
fi

case "$1" in
  flask) path=/health ;;
  patroni) path=/primary ;;
  vikunja) path=/api/v1/info ;;
  *) printf 'Unknown service.\n' >&2; exit 2 ;;
esac

base_url=${2%/}
if [[ ! $base_url =~ ^https?://[^/@?#[:space:]]+$ ]]; then
  printf 'Use an HTTP(S) origin without credentials or a path.\n' >&2
  exit 2
fi

if ! status=$(curl -q --silent --globoff --output /dev/null --write-out '%{http_code}' \
  --proto '=http,https' --connect-timeout 3 --max-time 10 -- "${base_url}${path}"); then
  printf 'Health request failed.\n' >&2
  exit 1
fi
printf '%s HTTP %s\n' "$1" "$status"
[[ $status == 200 ]]
