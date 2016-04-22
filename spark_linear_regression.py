from pyspark import SparkConf, SparkContext 
from pyspark.sql import SQLContext
from numpy import array
from pyspark.mllib.regression import LabeledPoint, LinearRegressionWithSGD
import pprint
from datetime import datetime
from pyspark.sql import Row
from pyspark.mllib.feature import StandardScaler
import pandas as pd
from pyspark.mllib.evaluation import RegressionMetrics
from pyspark.mllib.regression import RidgeRegressionWithSGD
from pyspark.mllib.regression import LassoWithSGD

conf = SparkConf().setMaster("local").setAppName("Cloudant Spark Connection")

cloudant_host = "3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix.cloudant.com"
cloudant_username = "3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix"
cloudant_password = "70d0f1455b7dd050452faa5d3650f0907bb98cde87f61fcde0cf57dbca8e3d7e"

# define cloud related configuration
conf.set("cloudant.host", cloudant_host)
conf.set("cloudant.username", cloudant_username)
conf.set("cloudant.password", cloudant_password)

# create Spark context and SQL context
sc = SparkContext(conf=conf)
sqlContext = SQLContext(sc)

cloudantdata = sqlContext.read.format("com.cloudant.spark").option("cloudant.host", cloudant_host).option("cloudant_username", cloudant_username).option("cloudant_password", cloudant_password).load("spark_data")

cloudantdata.cache()

cloudantdata.printSchema()
print "\n Rows in database = " + str(cloudantdata.count()) + "\n"

#cloudantdata.show()

#cloudantdata.describe('flux').show()

print cloudantdata.take(5)

def parseTimestamp(line):
	date = datetime.strptime(line.timestamp, '%Y-%m-%d %H:%M:%S')
	t = float(date.hour * 3600 + date.minute * 60 + date.second) # In seconds 
	# Timestamp in milliseconds since 1970
	return Row(flux=float(line.flux), lng=line.lng, lat=line.lat, timestamp=t)
	#return Row(flux=float(line.flux), timestamp=t)

# Convert timestamp values to floats
df = cloudantdata.map(parseTimestamp)

df.cache()

print df.take(5)

# This should be the maximum possible time
max_time = 23 * 3600 + 59 * 60 + 59
#max_time = 16 * 60
low = 0
high = 15 * 60
modelList = []

while low < max_time: # Temp should run once
	timeseries = df.filter(lambda x: low < x.timestamp < high)	

	#if timeseries.count() > 0:
	features = timeseries.map(lambda row: row[1:])
		#print "Possible points"
		#print features.collect()

	model = StandardScaler().fit(features)
	features_t = model.transform(features)
	
	label = timeseries.map(lambda row: row[0])
	labeled_data = label.zip(features_t)

	final_data = labeled_data.map(lambda row: LabeledPoint(row[0], row[1]))
	
	model = LinearRegressionWithSGD.train(final_data, 1000, .0000001, intercept=True)
		#model = RidgeRegressionWithSGD.train(final_data, 1000, .00000001, intercept=True)
		#model = LassoWithSGD.train(final_data, 1000, .00000001, intercept=True)
	modelList.append(model)
		

		#print ""
		#print "Model1 weights " + str(model.weights)
		#print ""
	prediObserRDD = final_data.map(lambda row: (float(model.predict(row.features)), row.label))

	metrics = RegressionMetrics(prediObserRDD)
	print "1 R2 = " + str(metrics.r2)
	print "1 Root mean squared error = " + str(metrics.rootMeanSquaredError)

	'''print "Predicting model "
	preds = final_data.map(lambda p: p.features)
	values = final_data.map(lambda p: p.label)
	print "Printing preds " 
	preds = model.predict(preds)
	print preds.take(10)
	print ""
	print "Printing label "
	print values.take(10)
	print ""'''
	
	low = high
	high += (15 * 60)



	

'''
# Get features from our adjusted dataframe
features = df.map(lambda row: row[1:])

# Scale features based on standard deviation and not mean
model = StandardScaler().fit(features)
features_t = model.transform(features)

# Get labels from df map
label = df.map(lambda row: row[0])

# Now combine our dense vectors with the labels
labeled_data = label.zip(features_t)

# Now let's get labeled points for our linear regression model (label, [features])
final_data = labeled_data.map(lambda row: LabeledPoint(row[0], row[1]))
print "Final labeled points"
print final_data.take(5)
print ""

#model = LinearRegressionWithSGD.train(final_data, 100, .0000000000001, intercept=True)

#print "Model weights" + str(model.weights)
trainingData, testingData = final_data.randomSplit([.8,.2],seed=1234)

model = LinearRegressionWithSGD.train(trainingData, 1000, .0001, intercept=True)

print "Model1 weights " + str(model.weights)

print "Predicting model "
preds = final_data.map(lambda p: p.features)
values = final_data.map(lambda p: p.label)
print "Printing preds " 
preds = model.predict(preds)
print preds.take(10)
print ""
print "Printing label "
print values.take(10)
print ""

valuesAndPreds = final_data.map(lambda p: (p.label, model.predict(p.features)))
MSE = valuesAndPreds.map(lambda (v,p): (v - p)**2).reduce(lambda x, y: x + y) / valuesAndPreds.count()
print "Mean Squared Error = " + str(MSE)


prediObserRDD = trainingData.map(lambda row: (float(model.predict(row.features)), row.label))

metrics = RegressionMetrics(prediObserRDD)


print "1 R2 = " + str(metrics.r2)
print "1 Root mean squared error = " + str(metrics.rootMeanSquaredError)
'''

pandaDF = df.toDF().toPandas()
print(pandaDF)

#%matplotlib inline

import matplotlib.pyplot as plt

values = pandaDF['flux']
labels = pandaDF['timestamp']
plt.gcf().set_size_inches(16, 12, forward=True)
plt.title('Flux vs Timestamp')

plt.plot(labels, values, 'ro')

plt.show()

sc.stop()

