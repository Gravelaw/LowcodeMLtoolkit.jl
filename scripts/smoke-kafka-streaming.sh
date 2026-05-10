#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
COMPOSE_FILE="$ROOT_DIR/infra/docker/compose.dev.yml"
TOPIC="${JULIAFLOW_KAFKA_TOPIC:-parallel.events}"
TMP_DIR="${JULIAFLOW_SMOKE_TMP:-$ROOT_DIR/tmp/kafka-smoke}"
EVENTS_FILE="$TMP_DIR/kafka-events.jsonl"
SINK_STATE="$TMP_DIR/sink-state.json"
SINK_OUTPUT="$TMP_DIR/sink-output.jsonl"
KAFKA_BIN="${JULIAFLOW_KAFKA_BIN:-/opt/kafka/bin}"
mkdir -p "$TMP_DIR"
rm -f "$EVENTS_FILE" "$SINK_STATE" "$SINK_OUTPUT"

docker compose -f "$COMPOSE_FILE" up -d kafka
for _ in $(seq 1 60); do
  if docker compose -f "$COMPOSE_FILE" exec -T kafka "$KAFKA_BIN/kafka-topics.sh" --bootstrap-server localhost:9092 --list >/dev/null 2>&1; then
    break
  fi
  sleep 2
done

docker compose -f "$COMPOSE_FILE" exec -T kafka "$KAFKA_BIN/kafka-topics.sh" --bootstrap-server localhost:9092 --create --if-not-exists --topic "$TOPIC" >/dev/null
cat <<JSONL | docker compose -f "$COMPOSE_FILE" exec -T kafka "$KAFKA_BIN/kafka-console-producer.sh" --bootstrap-server localhost:9092 --topic "$TOPIC" >/dev/null
{"topic":"$TOPIC","partition":0,"offset":1,"event_time_seconds":1,"region":"north","amount":10.0}
{"topic":"$TOPIC","partition":0,"offset":2,"event_time_seconds":2,"region":"south","amount":20.0}
{"topic":"$TOPIC","partition":0,"offset":3,"event_time_seconds":3,"region":"north","amount":30.0}
JSONL

docker compose -f "$COMPOSE_FILE" exec -T kafka "$KAFKA_BIN/kafka-console-consumer.sh" --bootstrap-server localhost:9092 --topic "$TOPIC" --from-beginning --max-messages 3 --timeout-ms 15000 > "$EVENTS_FILE"

JULIAFLOW_KAFKA_EVENTS_JSONL="$EVENTS_FILE" \
JULIAFLOW_STREAM_SINK_STATE_PATH="$SINK_STATE" \
JULIAFLOW_STREAM_SINK_OUTPUT_PATH="$SINK_OUTPUT" \
julia --project="$ROOT_DIR" "$ROOT_DIR/scripts/smoke-kafka-streaming.jl"
