#!/usr/bin/env bash
# Bat he thong Session 05 dung thu tu: database truoc, cac service sau.
set -euo pipefail
cd "$(dirname "$0")"

echo "1️⃣  Bat DATABASE (stack nay TAO RA mang quickbite5-net)..."
( cd quickbite5-db && docker compose up -d )

echo "⏳ Doi PostgreSQL san sang..."
for i in $(seq 1 30); do
  docker exec quickbite5-db pg_isready -U postgres >/dev/null 2>&1 && { echo "   ✅ DB accepting connections"; break; }
  sleep 2
done

echo "2️⃣  Bat 4 microservices + API Gateway..."
( cd stack && docker compose up -d --build --force-recreate )

# Gateway (Netty) CACHE ket qua phan giai DNS. Neu mot service vua duoc tao lai
# va doi IP, gateway van goi vao IP cu -> Connection refused.
# Restart gateway SAU CUNG de no phan giai lai toan bo.
echo "3️⃣  Restart gateway de lam moi DNS..."
( cd stack && docker compose restart api-gateway >/dev/null )

PORT=$(grep -E '^GATEWAY_HOST_PORT=' stack/.env | cut -d= -f2)
echo "⏳ Doi gateway san sang..."
for i in $(seq 1 45); do
  curl -fsS "http://localhost:${PORT}/actuator/health" >/dev/null 2>&1 && break
  sleep 2
done
echo
docker ps --filter name=quickbite5 --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo
echo "🎉 San sang. Moi request di qua gateway:"
echo "   curl http://localhost:${PORT}/api/v1/users"
