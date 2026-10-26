#!/usr/bin/env bash
# Xoa Prometheus + Node Exporter.
set -e
cd "$(dirname "$0")"

KEEP=0
[ "$1" = "--giu-du-lieu" ] && KEEP=1

if [ "$KEEP" = "1" ]; then
  docker compose down
  echo "Da xoa container, GIU lai lich su metrics trong volume."
else
  docker compose down -v
  echo "Da xoa container VA toan bo lich su metrics."
  echo "  (muon giu lai lich su: ./xoa-monitoring.sh --giu-du-lieu)"
fi

echo
echo "Neu da sua build.gradle / application.yml khi hoc, tra chung ve ban goc:"
echo "  cd ../../ && git checkout -- session-05/"
echo "  cd session-05 && ./build-all.sh order-service user-service && ./start-all.sh"
