#!/usr/bin/env bash
# Dung Prometheus + Node Exporter cho Session 13.
set -e
cd "$(dirname "$0")"

if ! docker network ls --format '{{.Name}}' | grep -q '^quickbite5-net$'; then
  echo "❌ Chua co mang quickbite5-net."
  echo "   Prometheus can cac service de keo metrics. Hay bat Session 05 truoc:"
  echo "     cd ../../session-05 && ./start-all.sh"
  exit 1
fi

echo "==> Dang dung Prometheus va Node Exporter..."
docker compose up -d

echo "==> Doi Prometheus san sang..."
for i in $(seq 1 30); do
  docker exec quickbite-prometheus wget -qO- http://localhost:9090/-/healthy >/dev/null 2>&1 && break
  sleep 1
done

if ! docker exec quickbite-prometheus wget -qO- http://localhost:9090/-/healthy >/dev/null 2>&1; then
  echo "    ⚠️  Prometheus chua phan hoi sau 30s. Xem log:"
  echo "        docker compose logs --tail=30 prometheus"
  exit 1
fi

echo "==> Doi chu ky scrape dau tien (15s)..."
sleep 16
echo
echo "Prometheus da chay."
echo "  Xem targets : docker exec quickbite-prometheus wget -qO- http://localhost:9090/api/v1/targets"
echo "  Kiem tra    : ./check.sh"
echo
echo "Luu y: KHONG mo cong 9090 ra ngoai — Prometheus chi truy cap duoc trong mang noi bo."
