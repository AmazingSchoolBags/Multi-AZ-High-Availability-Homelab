#!/usr/bin/env bash
set -euo pipefail

if (( $# != 1 )); then
  printf 'Usage: %s {write-origin-read-origin|write-origin-read-replica}\n' "${0##*/}" >&2
  exit 2
fi

: "${S3_TEST_BUCKET:?Set S3_TEST_BUCKET to a disposable bucket}"
: "${S3_WRITE_ENDPOINT:?Set S3_WRITE_ENDPOINT}"
case "$1" in
  write-origin-read-origin) read_endpoint=$S3_WRITE_ENDPOINT ;;
  write-origin-read-replica) read_endpoint=${S3_READ_ENDPOINT:?Set S3_READ_ENDPOINT} ;;
  *) printf 'Unknown test mode.\n' >&2; exit 2 ;;
esac

for endpoint in "$S3_WRITE_ENDPOINT" "$read_endpoint"; do
  if [[ ! $endpoint =~ ^https://[^/@?#[:space:]]+$ ]]; then
    printf 'Use HTTPS origins without embedded credentials.\n' >&2
    exit 2
  fi
done

umask 077
tmp=$(mktemp -d)
key="homelab-smoke/${tmp##*/}"
uploaded=false

s3() {
  local endpoint=$1
  shift
  aws --no-cli-pager --cli-connect-timeout 5 --cli-read-timeout 10 \
    --endpoint-url "$endpoint" s3api "$@" >/dev/null 2>&1
}

cleanup() {
  local result=$?
  if [[ $uploaded == true ]] && ! s3 "$S3_WRITE_ENDPOINT" delete-object \
    --bucket "$S3_TEST_BUCKET" --key "$key"; then
    printf 'Object cleanup failed. Check the disposable bucket.\n' >&2
    result=1
  fi
  rm -f -- "$tmp/input" "$tmp/output"
  rmdir -- "$tmp"
  exit "$result"
}

trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
printf 'Multi-AZ S3 smoke test\n' > "$tmp/input"

uploaded=true
if ! s3 "$S3_WRITE_ENDPOINT" put-object --bucket "$S3_TEST_BUCKET" \
  --key "$key" --body "$tmp/input"; then
  printf 'Upload failed.\n' >&2
  exit 1
fi
if ! s3 "$read_endpoint" get-object --bucket "$S3_TEST_BUCKET" \
  --key "$key" "$tmp/output" || ! cmp -s -- "$tmp/input" "$tmp/output"; then
  printf 'Read or content comparison failed.\n' >&2
  exit 1
fi
printf 'Object content verified.\n'
