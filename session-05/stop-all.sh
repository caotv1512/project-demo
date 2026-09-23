#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"
echo "1️⃣  Tat cac service..."; ( cd stack && docker compose down )
echo "2️⃣  Tat database (GIU du lieu)..."; ( cd quickbite5-db && docker compose down )
echo "✅ Da tat. Du lieu van con trong volume."
