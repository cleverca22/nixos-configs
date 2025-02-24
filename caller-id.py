#!/usr/bin/env python
# [clever@amd-nixos:~/apps/nixos-configs]$ nix-shell -p 'python3.withPackages (ps: [ ps.paho-mqtt ps.pygobject3 ])' gobject-introspection libnotify

import paho.mqtt.client as mqtt
import time
import gi
import os
gi.require_version('Notify', '0.7')
from gi.repository import Notify

Notify.init("caller-id")

def on_connect(client_instance, userdata, flags, rc):
    print("on_connect")
    client.subscribe("caller-id/#");

def on_log(client_instance, userdata, level, buff):
    print(buff)

def on_message(client_instance, userdata, msg):
    payload = msg.payload.decode("utf-8").strip()
    print("on_message, retain:%s topic:%40s payload: %s" % (msg.retain, msg.topic, payload));
    if (msg.topic == "caller-id/status"):
      note = Notify.Notification.new("caller id status", payload)
      note.show()
    elif (msg.topic == "caller-id/event"):
      note = Notify.Notification.new("caller id", payload)
      note.show()

def on_disconnect(client_instance, userdata, rc):
    print("on_disconnect")

client = mqtt.Client(client_id="test-client")
client.on_connect = on_connect
client.on_message = on_message
client.on_disconnect = on_disconnect
#client.on_log = on_log
client.username_pw_set("full_access", os.environ["CALLERID_PW"]);
client.connect("nas.localnet", keepalive=600)
client.loop_forever(retry_first_connection = True)
