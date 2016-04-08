import RPi.GPIO as GPIO, time
import paho.mqtt.client as mqtt
import json
import time
import datetime

# URI == 4
# this implementation is testing overnight running capabilities
# the client sets a keep alive timout of 1 hour
# this should prevent unwanted disconnects from inactivity
# this version will publish indidual values


def on_connect(client, userdata, rc):
	print("Successfully connected")

def on_message(client, userdata, msg):
	string = "Message received: \n \t Topic: %s \n \t Message %s"
	print (string % (msg.topic, str(msg.payload)))

def on_publish(mosq, obj, mid):
	pass

def on_disconnect(pahoClient, obj, rc):
	print "Disconnected"


def RCtime(RCpin):
	reading = 0
	GPIO.setup(RCpin, GPIO.OUT)
	GPIO.output(RCpin, GPIO.LOW)
	time.sleep(0.1)
	GPIO.setup(RCpin, GPIO.IN)
	while(GPIO.input(RCpin) == GPIO.LOW):
		reading += 1
	return reading

#while 1:
#	print RCtime(22)

# begin flow of control

#time.sleep(20)
GPIO.setmode(GPIO.BOARD)

client = mqtt.Client()
client.on_connect = on_connect
client.on_message = on_message
client.on_publish = on_publish
client.on_disconnect = on_disconnect

#client.connect("169.55.155.236", 9999, 60) #VCL
client.connect("158.85.106.197", 9999, 3600) #VCL, keep alive for one hour


data = {}
data['lat'] = 34.6775 #34.70724
data['lng'] = -82.828056 #-82.773239
data['URI'] = 4

stime = time.time()
count = 0
sum = 0
while 1:
	reading = RCtime(22)
	etime = time.time()
	if(etime - stime < 30):
                continue
	print reading
        data['flux'] = reading
        data['timestamp'] = datetime.datetime.fromtimestamp(etime).strftime('%Y-%m-%d %H:%M:%S')
        json_data = json.dumps(data)
	client.publish("clemson", json_data)
	stime = time.time() 
