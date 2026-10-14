#!/usr/bin/env bash
set -e
cd "$(dirname "$0")"
docker compose down -v --remove-orphans
echo "Da xoa VPS gia lap. Chay ./tao-vps.sh de dung lai ban moi tinh."
