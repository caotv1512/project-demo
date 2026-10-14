#!/usr/bin/env bash
# Dung VPS gia lap cho Session 11: Ubuntu 24.04 + Nginx + SSH.
set -e
cd "$(dirname "$0")"

if ! docker network ls --format '{{.Name}}' | grep -q '^quickbite5-net$'; then
  echo "❌ Chua co mang quickbite5-net."
  echo "   Nginx can co API Gateway de chuyen tiep request toi. Hay bat Session 05 truoc:"
  echo "     cd ../../session-05 && ./start-all.sh"
  exit 1
fi

echo "==> Dang dung VPS gia lap (co Nginx)..."
docker compose up -d --build
echo "==> Doi SSH va Nginx san sang..."
for i in $(seq 1 30); do
  nc -z localhost 2223 2>/dev/null && nc -z localhost 8880 2>/dev/null && break
  sleep 1
done
echo
echo "VPS gia lap da chay."
echo "  SSH  : ssh -p 2223 root@localhost        (mat khau: quickbite)"
echo "  HTTP : http://localhost:8880             (= cong 80 cua VPS that)"
echo "  HTTPS: https://localhost:8443            (= cong 443 cua VPS that)"
echo "  Vao thang (= Web Console): docker exec -it vps11 bash"
