#!/usr/bin/env bash
# ⚠️ XOA TOAN BO du lieu Session 05 de demo lai tu dau.
set -euo pipefail
cd "$(dirname "$0")"
echo "⚠️  Se XOA SACH du lieu database cua Session 05."
read -r -p "   Go 'yes' de tiep tuc: " a
[ "$a" = yes ] || { echo "Da huy."; exit 0; }
( cd stack        && docker compose down -v ) 2>/dev/null || true
( cd quickbite5-db && docker compose down -v ) 2>/dev/null || true
docker rmi -f stack-api-gateway stack-user-service stack-restaurant-service \
              stack-order-service stack-notification-service 2>/dev/null || true
echo "✅ Da reset. Chay lai:  ./start-all.sh"
