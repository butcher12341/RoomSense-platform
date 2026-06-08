#!/bin/sh
set -eu

MQTT_USER="${MQTT_USER:-roomsense_esp32}"
MQTT_PASSWORD="${MQTT_PASSWORD:-roomsense-demo-pass}"
MODE="${1:-snapshot}"

publish() {
  topic="$1"
  message="$2"
  retain="${3:-}"

  if [ "$retain" = "retain" ]; then
    docker compose exec -T mosquitto mosquitto_pub \
      -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
      -t "$topic" -m "$message" -r
  else
    docker compose exec -T mosquitto mosquitto_pub \
      -u "$MQTT_USER" -P "$MQTT_PASSWORD" \
      -t "$topic" -m "$message"
  fi
}

seed_snapshot() {
  publish "roomsense/room1/status" "online" "retain"
  publish "roomsense/room1/telemetry" '{"temperature":24.5,"humidity":52.0,"co2":830}' "retain"

  publish "roomsense/room2/status" "online" "retain"
  publish "roomsense/room2/telemetry" '{"temperature":27.1,"humidity":61.0,"co2":1450}' "retain"
}

seed_stream() {
  seed_snapshot

  publish "roomsense/room1/telemetry" '{"temperature":44.1,"humidity":51.0,"co2":760}'
  publish "roomsense/room2/telemetry" '{"temperature":120.4,"humidity":58.0,"co2":1120}'
  sleep 5

  publish "roomsense/room1/telemetry" '{"temperature":24.3,"humidity":91.5,"co2":120}'
  publish "roomsense/room2/telemetry" '{"temperature":26.8,"humidity":99.0,"co2":1280}'
  sleep 5

  publish "roomsense/room1/telemetry" '{"temperature":24.7,"humidity":72.0,"co2":2110}'
  publish "roomsense/room2/telemetry" '{"temperature":27.2,"humidity":70.5,"co2":1510}'
  sleep 5

  publish "roomsense/room1/telemetry" '{"temperature":25.0,"humidity":53.0,"co2":1040}'
  publish "roomsense/room2/telemetry" '{"temperature":27.8,"humidity":62.0,"co2":2020}'
  sleep 5

  publish "roomsense/room1/telemetry" '{"temperature":24.8,"humidity":52.0,"co2":790}'
  publish "roomsense/room2/telemetry" '{"temperature":27.0,"humidity":60.0,"co2":760}'
}

case "$MODE" in
  snapshot)
    seed_snapshot
    ;;
  --stream|stream)
    seed_stream
    ;;
  *)
    echo "Usage: $0 [snapshot|--stream]" >&2
    exit 1
    ;;
esac

echo "RoomSense demo data published."
