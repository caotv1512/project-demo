#!/usr/bin/env bash
# Xoa cum EFK. Mac dinh GIU du lieu index va buffer.
#   ./xoa-efk.sh              -> xoa container, giu volume
#   ./xoa-efk.sh --xoa-het    -> xoa ca volume (mat toan bo log da luu)
set -e
cd "$(dirname "$0")"

if [ "${1:-}" = "--xoa-het" ]; then
  echo "==> Xoa container VA volume (mat toan bo index log)..."
  docker compose down -v
else
  echo "==> Xoa container, GIU volume du lieu..."
  docker compose down
  echo "    Volume con lai:"
  docker volume ls --filter name=efk_ --format '      {{.Name}}'
fi
echo "Xong."
