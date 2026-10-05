#!/usr/bin/env bash
# Dung "VPS gia lap" tren may ban: Ubuntu 24.04 + SSH, cong 2222.
set -e
cd "$(dirname "$0")"
echo "==> Dang dung VPS gia lap..."
docker compose up -d --build
echo "==> Doi SSH san sang..."
for i in $(seq 1 30); do
  if nc -z localhost 2222 2>/dev/null; then echo "    SSH da san sang (cong 2222)"; break; fi
  sleep 1
done
echo
echo "VPS gia lap da chay."
echo "  Dang nhap root (mat khau: quickbite):"
echo "    ssh -p 2222 root@localhost"
echo "  Hoac vao thang khong can mat khau (= Web Console cua nha cung cap VPS):"
echo "    docker exec -it vps-gia-lap bash"
