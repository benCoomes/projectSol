
# Use Cloudant to create a Cloudant client using account
from cloudant.account import Cloudant

# Using paho mqtt
import paho.mqtt.client as mqtt
import json

mqtt_client = mqtt.Client()
sol_db, backup_db = None, None

def on_connect(client, userdata, rc):
	print("Successfully conncected")
	mqtt_client.subscribe("clemson")

def on_message(client, userdata, msg):
	global sol_db, backup_dp

	string = "Message received: \n \t Topic: %s \n \t Message %s"
	print(string % (msg.topic, str(msg.payload)))

	data = json.loads(msg.payload)

	my_doc = sol_db.create_document(data) 

	my_doc_backup = backup_db.create_document(data)

	if my_doc.exists() and my_doc_backup.exists():
		print "Success!"

def on_publish(mosq, obj, mid):
	pass

def on_disconnect(pahoClient, obj, rc):
    print "Disconnected"

def setup_mqtt(HOST, PORT):
	global mqtt_client

	mqtt_client = mqtt.Client()
	mqtt_client.on_connect = on_connect
	mqtt_client.on_message = on_message
	mqtt_client.on_publish = on_publish
	mqtt_client.on_disconnect = on_disconnect

	mqtt_client.connect(HOST, PORT, 60) # VCL

def setup_db(username, password, url):
	
	dbname = "clemson_data"

	client = Cloudant(username, password, url=url)

	client.connect()

	# Perform client tasks...
	session = client.session()
	print 'Username: {0}'.format(session['userCtx']['name'])
	databases = client.all_dbs()
	
	if not databases:
		db = client.create_database(dbname)
	else:
		db = client[dbname]

	print 'Databases: {0}'.format(client.all_dbs())

	return db

if __name__ == "__main__":
	sol_db = setup_db("3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix", "70d0f1455b7dd050452faa5d3650f0907bb98cde87f61fcde0cf57dbca8e3d7e", "https://3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix:70d0f1455b7dd050452faa5d3650f0907bb98cde87f61fcde0cf57dbca8e3d7e@3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix.cloudant.com")
	backup_db = setup_db("87f41cc8-092b-46a0-b505-370a59412bc3-bluemix", "cfe1dbf85164584c700e4bce6c10b81a71563df37929a6c442e4362e9745a290", "https://87f41cc8-092b-46a0-b505-370a59412bc3-bluemix:cfe1dbf85164584c700e4bce6c10b81a71563df37929a6c442e4362e9745a290@87f41cc8-092b-46a0-b505-370a59412bc3-bluemix.cloudant.com")
	setup_mqtt("158.85.106.197", 9999)
	mqtt_client.loop_forever()

