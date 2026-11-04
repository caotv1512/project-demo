#!/usr/bin/env bash
# Dat mot don hang voi trace.id do minh tu dat, de tim lai trong Kibana.
#   ./test-trace-request.sh                      -> trace.id tu sinh theo gio
#   ./test-trace-request.sh trace-demo-001       -> trace.id do minh dat
set -e
cd "$(dirname "$0")"
PORT=$(grep -E '^GATEWAY_HOST_PORT=' ../session-05/stack/.env 2>/dev/null | cut -d= -f2)
PORT="${PORT:-8000}"
TRACE_ID="${1:-trace-$(date +%H%M%S)}"

echo "==> trace.id = $TRACE_ID"
curl -i -s -X POST \
  "http://localhost:$PORT/api/v1/orders?userId=1&restaurantId=1" \
  -H "X-Trace-Id: $TRACE_ID" | grep -iE '^HTTP/|^X-Trace-Id|orderId'

echo
echo "Tim trong Kibana Discover:  trace.id : \"$TRACE_ID\""
echo "Hoac tim bang dong lenh:"
echo "  curl -s 'http://127.0.0.1:9200/quickbite-*/_search?q=trace.id:\"$TRACE_ID\"&size=20&sort=@timestamp:asc' | python3 -m json.tool"
