# projectSol

To Project Sol Members,

Instructions for setting up Mosquito broker:

	1) Get access to VCL or another remote machine (Maybe can use this machine? 158.85.106.197)
	2) git clone https://github.com/benCoomes/projectSol.git
	3) cd projectSol
	4) chmod u+x mosquitto.sh
	5) ./mosquttio.sh (This should install the broker hopefully)
	6) mosquitto -p 9999 (I've been using port 9999, but you guys could make it something else as long as you also change the publish/subscribe scripts)

Instructions for setting up a subscriber are as follows:

	1) Get access to VCL or another remote machine (Maybe can use this machine? 158.85.106.197)
	2) git clone https://github.com/benCoomes/projectSol.git
	3) cd projectSol
	4) nohup python cloudantclient.py &
	5) nohup python sparkclienst.py &
	notes:
		These scripts may need to be adjusted but the adjustments should be quite simple. This will set up two subscribers that push data to two databases each, for a total of four databases. The cloudantclient.py pushes data to our original database, though much of the data in that is quite bad. The sparkclient.py pushes data to another database which does not contain malformed data and is what I've been using for Spark. You guys can decide what you want to do, but it should be simple changes.

Instructions for Spark:

	1) Get access to VCL or another remote machine (Maybe can use this machine which already has spark? 158.85.106.205)
	2) git clone https://github.com/benCoomes/projectSol.git
	3) cd <spark-directory>
	4) bin/spark-submit --master local[4] --jars ../spark-cloudant/cloudant-spark-v1.6.3-125.jar ../projectSol/spark_linear_regression.py 
	notes:
		This script currently converts all timestamps to floats starting from 0 and up to the maximum number of seconds in a day. From here, it moves through and creates linear regression models for each 15 minute sliding window. These models can then be used to predict the solar energy for an available time with better accuracy (hopefully one day maybe?). You guys should definitely use weatherunderground's API to incorporate weather features as well. It shouldn't be too difficult, but if things start going wrong, adjusting the stepSize in the training of the model could help. I've been adjusting it by guess and check, but maybe there is a better way to do it?

Instructions for sensor scripts: 
	1) Get access to a raspberry pi that can be left on with the sensor circuit connected (email Ben Coomes or Jon Francis: see google doc folder for emails)
	2) git clone https://github.com/benCoomes/projectSol.git
	3) cd projectSol
	4) open lightsensor3.py with your favorite text editor
	5) modify the ip address in the client.connect() fucntion to match the ip address of the mosquitto broker
	6) modify the port in the client.connect() function to match the ip address of the mosquitto broker
	7) modify the latitude and longitude values to match wherever you leave the sensor (we used a phone to get these values)
	8) modify the URI so that it is unique (we used 1, 2, 3, and 4)
	9) python lightsensor3.py

	You will probably need to install the paho mqtt and GPIO libraries for python. The other lightsensors are slightly different, but lightsensor3 is the best. 


Instructions for the Shiny application
	1) git clone https://github/benCoomes/projectSol.git
	2) cd projectSol/clemson_data
	3) this is the directory for the shiny application, shiny applications need paticular directory structures so be careful makeing directory-level changes
	4) make a shinyapps.io account
	5) in an R sesssion: install.packages('rsconnect')
	6) configure rsconnect, see tutorial here: http://shiny.rstudio.com/articles/shinyapps.html
	7) change the username and password fields to match the ones for your cloudant database
	8) deploy the application to shinyapps.io

	I would reccomend using R studio for developing and deploying anything with shiny. Shiny and R Studio are made by the same people, so the integration
	comes by default and is incredibly helpful. You can view our instance of the application here, if it is still running: 
	https://bencoomes.shinyapps.io/clemson_data/  There are many helpful videos about using Shiny, I reccomend the 2-hour one on R shiny's website. 


Instructions for cloudant database:
	1) Use bluemix to get a free account
	2) set up database, starting from within bluemix
	3) remember databse information, for use in all data consumer applications and the subscriber


Best of luck guys.

Cheers,
Matthew Furlong
Ben Coomes
Jon Francis
