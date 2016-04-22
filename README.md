# projectSol

To Project Sol Members,

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