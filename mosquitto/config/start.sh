set -eu

rm -f /tmp/roomsense-passwd
mosquitto_passwd -b -c /tmp/roomsense-passwd roomsense_esp32 roomsense-demo-pass
mosquitto_passwd -b /tmp/roomsense-passwd homeassistant roomsense-demo-pass

cp /mosquitto/config/acl /tmp/roomsense-acl
chown mosquitto:mosquitto /tmp/roomsense-passwd /tmp/roomsense-acl
chmod 0600 /tmp/roomsense-passwd /tmp/roomsense-acl

exec /usr/sbin/mosquitto -c /mosquitto/config/mosquitto.conf

