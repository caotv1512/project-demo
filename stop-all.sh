#!/usr/bin/env bash
# Tat he thong DUNG THU TU NGUOC LAI: backend truoc, database sau.
# (Ai tao ra tai nguyen thi phai song lau hon nguoi dung tai nguyen do.)
set -euo pipefail
cd "$(dirname "$0")"

echo "1️⃣  Tat restaurant-service (neu dang chay)..."
( cd bai-tap-1-restaurant && docker compose down ) 2>/dev/null || true

echo "2️⃣  Tat backend..."
( cd quickbite-backend && docker compose down )

echo "3️⃣  Tat database (GIU NGUYEN du lieu - khong dung co -v)..."
( cd quickbite-db && docker compose down )

echo
echo "✅ Da tat. Du lieu database VAN CON trong named volume."
echo "   Muon xoa sach ca du lieu: ./reset-demo.sh"
