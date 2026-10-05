#!/usr/bin/env bash
# Xoa sach VPS gia lap de lam lai tu dau.
set -e
cd "$(dirname "$0")"
docker compose down -v --remove-orphans
echo "Da xoa VPS gia lap. Chay ./tao-vps.sh de dung lai ban moi tinh."
echo
echo "Luu y: khoa SSH ~/.ssh/quickbite_vps_ed25519 van con tren may ban."
echo "Muon xoa luon:  rm -f ~/.ssh/quickbite_vps_ed25519*"
