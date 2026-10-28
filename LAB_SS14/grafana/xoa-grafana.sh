#!/usr/bin/env bash
# Go Grafana. Mac dinh xoa luon dashboard va cau hinh da tao.
set -e
cd "$(dirname "$0")"
if [ "${1:-}" = "--giu-du-lieu" ]; then
  docker compose down
  echo "Da xoa container, GIU lai dashboard va user trong volume."
else
  docker compose down -v
  echo "Da xoa container VA toan bo dashboard, user, data source da tao."
  echo "  (muon giu lai: ./xoa-grafana.sh --giu-du-lieu)"
fi
