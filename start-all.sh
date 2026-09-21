#!/usr/bin/env bash
# Bat toan bo he thong DUNG THU TU: database truoc, backend sau.
set -euo pipefail
cd "$(dirname "$0")"

echo "1️⃣  Bat stack DATABASE (stack nay TAO RA mang quickbite-net)..."
( cd quickbite-db && docker compose up -d )

echo "⏳ Doi PostgreSQL san sang..."
for i in $(seq 1 30); do
  docker exec quickbite-db pg_isready -U postgres >/dev/null 2>&1 && { echo "   ✅ DB accepting connections"; break; }
  sleep 2
done

# --force-recreate: BAT BUOC.
# Neu database vua bi xoa sach (docker compose down -v) ma container app van
# dang chay tu truoc, app se KHONG chay lai schema.sql/data.sql -> bang du lieu
# khong duoc tao lai. Ep tao lai container de app khoi dong lai tu dau.
echo "2️⃣  Bat stack BACKEND (dung mang external do DB da tao)..."
( cd quickbite-backend && docker compose up -d --build --force-recreate )

if [ "${1:-}" = "--with-restaurant" ]; then
  echo "3️⃣  Bat restaurant-service (Java 21 - bai tap 1)..."
  ( cd bai-tap-1-restaurant && docker compose up -d --build --force-recreate )
fi

echo
echo "⏳ Doi ung dung khoi dong..."
for i in $(seq 1 45); do
  curl -fsS http://localhost:8081/actuator/health >/dev/null 2>&1 && break
  sleep 2
done

echo
docker ps --filter name=quickbite --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo
echo "🎉 San sang. Thu ngay:"
echo "   curl http://localhost:8081/actuator/health"
echo "   curl http://localhost:8081/api/users"
