#!/usr/bin/env bash
# Dung Grafana cho Session 14. Can Prometheus cua Session 13 chay truoc.
set -e
cd "$(dirname "$0")"
PORT="${GRAFANA_HOST_PORT:-3000}"

if ! docker ps --format '{{.Names}}' | grep -q '^quickbite-prometheus$'; then
  echo "❌ Chua co Prometheus. Grafana khong co nguon du lieu de ve."
  echo "   Bat Session 13 truoc:"
  echo "     cd ../../LAB_SS13/monitoring && ./tao-monitoring.sh"
  exit 1
fi

# Chinh Grafana cua bai dang chay san thi khong phai loi.
if docker ps --format '{{.Names}}\t{{.Ports}}' | grep -q "^quickbite-grafana.*:$PORT->"; then
  echo "ℹ️  Grafana da chay san tren cong $PORT."
  echo "    Mo trinh duyet : http://localhost:$PORT"
  echo "    Dung lai tu dau: ./xoa-grafana.sh --giu-du-lieu && ./tao-grafana.sh"
  exit 0
fi

if lsof -nP -iTCP:"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
  echo "❌ Cong $PORT dang bi chiem boi tien trinh khac (khong phai Grafana)."
  echo "   Xem ai dang giu:"
  echo "     lsof -nP -iTCP:$PORT -sTCP:LISTEN"
  echo "   Hoac dung cong khac:"
  echo "     GRAFANA_HOST_PORT=3002 ./tao-grafana.sh"
  exit 1
fi

echo "==> Dang dung Grafana tren cong $PORT..."
GRAFANA_HOST_PORT="$PORT" docker compose up -d

echo "==> Doi Grafana san sang..."
for i in $(seq 1 60); do
  curl -s "http://localhost:$PORT/api/health" | grep -q '"database": *"ok"' && break
  sleep 2
done

if ! curl -s "http://localhost:$PORT/api/health" | grep -q '"database": *"ok"'; then
  echo "    ⚠️  Grafana chua phan hoi. Xem log:"
  echo "        docker compose logs --tail=30 grafana"
  exit 1
fi

echo
echo "Grafana da chay."
echo "  Mo trinh duyet : http://localhost:$PORT"
echo "  Tai khoan      : admin / ${GF_ADMIN_PASSWORD:-quickbite_lab_2026}"
echo "  Kiem tra       : ./check.sh"
echo
echo "Luu y: doi mat khau ngay o lan dang nhap dau. KHONG commit mat khau that len repo."
