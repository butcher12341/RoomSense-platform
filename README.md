# RoomSense Platform

IoT platforma za praćenje kvalitete zraka u prostorijama. Temelji se na Home Assistantu i Mosquitto MQTT brokeru, pokrenuta putem Dockera.

## Pokretanje

```bash
docker-compose up -d
```

Home Assistant dostupan na: `http://localhost:8123`

## Arhitektura

```
ESP32 → Mosquitto (MQTT) → Home Assistant → REST API → Web aplikacija
```

## MQTT topici

### Senzori (ESP32 → HA)

| Topic | Format | Opis |
|---|---|---|
| `roomsense/room1/telemetry` | JSON | Sva mjerenja sobe 1 |
| `roomsense/room2/telemetry` | JSON | Sva mjerenja sobe 2 |
| `roomsense/room1/status` | string | `online` / `offline` |
| `roomsense/room2/status` | string | `online` / `offline` |

Primjer JSON payloada:
```json
{"temperature": 24.5, "humidity": 46.0, "co2": 650}
```

### Aktuatori (HA → ESP32)

| Topic | Payload | Opis |
|---|---|---|
| `room1/aircond` | `1` / `0` | Klimatizacija |
| `room1/airflow` | `1` / `0` | Ventilacija |
| `room1/dehumid` | `1` / `0` | Odvlaživanje |

## Home Assistant REST API

Baza URL-a: `http://localhost:8123`

Autentifikacija: `Authorization: Bearer <TOKEN>`

Token se generira u HA: **Profil → Security → Long-Lived Access Tokens**

### Senzori

#### Trenutno stanje

```
GET /api/states/sensor.roomsense_room1_temperature
GET /api/states/sensor.roomsense_room1_humidity
GET /api/states/sensor.roomsense_room1_co2
GET /api/states/sensor.roomsense_room2_temperature
GET /api/states/sensor.roomsense_room2_humidity
GET /api/states/sensor.roomsense_room2_co2
```

Primjer odgovora:
```json
{
  "entity_id": "sensor.roomsense_room1_temperature",
  "state": "24.5",
  "attributes": {
    "unit_of_measurement": "°C",
    "device_class": "temperature"
  },
  "last_updated": "2026-06-07T12:00:00+00:00"
}
```

#### Povijest mjerenja

```
GET /api/history/period/<ISO_TIMESTAMP>?filter_entity_id=sensor.roomsense_room1_temperature,sensor.roomsense_room1_humidity,sensor.roomsense_room1_co2
```

### Aktuatori

#### Stanje aktuatora

```
GET /api/states/switch.klimatizacija
GET /api/states/switch.ventilacija
GET /api/states/switch.odvlazivanje
```

#### Uključivanje / isključivanje

```
POST /api/services/switch/turn_on
POST /api/services/switch/turn_off
```

Body:
```json
{"entity_id": "switch.klimatizacija"}
```

#### Provjera je li HA aktivan

```
GET /api/
```

### Primjer poziva (Spring Boot)

```java
RestTemplate restTemplate = new RestTemplate();
HttpHeaders headers = new HttpHeaders();
headers.set("Authorization", "Bearer " + haToken);
HttpEntity<String> entity = new HttpEntity<>(headers);

// Dohvat stanja senzora
ResponseEntity<String> response = restTemplate.exchange(
    "http://localhost:8123/api/states/sensor.roomsense_room1_temperature",
    HttpMethod.GET, entity, String.class
);

// Uključivanje aktuatora
String body = "{\"entity_id\": \"switch.klimatizacija\"}";
HttpEntity<String> postEntity = new HttpEntity<>(body, headers);
restTemplate.exchange(
    "http://localhost:8123/api/services/switch/turn_on",
    HttpMethod.POST, postEntity, String.class
);
```

## Alarmi i upozorenja

Automatizacije su definirane u `home-assistant/automations.yaml`:

| Uvjet | Prag | Akcija |
|---|---|---|
| CO2 visoka razina | > 1000 ppm | Notifikacija u HA |
| CO2 kritična razina | > 2000 ppm | Notifikacija u HA |
| CO2 normalizacija | < 800 ppm | Uklanja notifikacije |
| Temperatura previsoka | > 35 °C | Notifikacija u HA |
| Temperatura preniska | < 15 °C | Notifikacija u HA |
| Temperatura normalizacija | 15–35 °C | Uklanja notifikacije |
