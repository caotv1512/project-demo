#!/usr/bin/env bash
# ==========================================================================
#  reset-demo.sh - Dua moi thu ve trang thai SACH de demo lai tu dau
#
#  ⚠️  XOA TOAN BO DU LIEU DATABASE (dung co -v).
#      Dung script nay giua hai ca day, hoac khi muon chay lai init-db.sql.
# ==========================================================================
set -euo pipefail
cd "$(dirname "$0")"

echo "⚠️  Script nay se XOA SACH du lieu database cua demo QuickBite."
read -r -p "   Go 'yes' de tiep tuc: " ans
[ "$ans" = "yes" ] || { echo "Da huy."; exit 0; }

echo "🧹 Go bo cac stack..."
( cd bai-tap-1-restaurant && docker compose down -v )  2>/dev/null || true
( cd quickbite-backend    && docker compose down -v )  2>/dev/null || true
( cd quickbite-db         && docker compose down -v )  2>/dev/null || true
( cd lab0-test            && docker compose down    )  2>/dev/null || true

echo "🧹 Xoa image do demo tu build..."
docker rmi -f quickbite-backend-quickbite-user \
              bai-tap-1-restaurant-quickbite-restaurant \
              quickbite-user-service:v1 2>/dev/null || true

echo
echo "✅ Da reset. Trang thai hien tai:"
docker ps -a --filter name=quickbite --format "table {{.Names}}\t{{.Status}}" || true
docker network ls | grep quickbite || echo "   (khong con mang quickbite-net - dung nhu mong doi)"
echo
echo "👉 Chay lai demo:  ./start-all.sh"
