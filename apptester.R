library(ggplot2)
library(httr)
library(jsonlite)
library(magrittr)

username <- "3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix"
password <- "70d0f1455b7dd050452faa5d3650f0907bb98cde87f61fcde0cf57dbca8e3d7e"

# #http <- "https://3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix.cloudant.com/clemson_data/_all_docs?limit=1000&include_docs=true&descending=true"
# http <- "https://3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix.cloudant.com/clemson_data/_all_docs?include_docs=true"
# httpResponse <- GET(http, authenticate(username, password))
# 
# documents <- fromJSON(toString(content(httpResponse, as = "text" , encoding = "UTF-8")))
# data <- documents[['rows']]
# df <- data[['doc']]
# 
# 
# select <- df$URI == 2
# 
# #seperate and clean data for UID 2
# rpi2 <- df[select, ]
# rpi2 <- rpi2[1:7]
# rpi2 <- rpi2[complete.cases(rpi2),]
# rpi2$flux <- as.numeric(rpi2$flux)
# rpi2$timestamp <- as.POSIXct(rpi2$timestamp, format = "%Y-%m-%d %H:%M:%S")
# 
# fmean <- mean(rpi2$flux)
# fdev <- sd(rpi2$flux)
# outliers <- rpi2$flux > (fmean + 3 * fdev)
# rpi2 <- rpi2[!outliers, ]
# 
# rpi2 <- rpi2[order(rpi2$timestamp),]
# 
# # seperate and clean data for UID 1
# select <- df$URI == 1
# rpi1 <- df[select, ]
# rpi1 <- rpi1[c(1, 2, 4, 6, 7, 8, 9)]
# rpi1 <- rpi1[complete.cases(rpi1),]
# rpi1$flux <- as.numeric(rpi1$flux)
# rpi1$timestamp <- as.POSIXct(rpi1$timestamp, format = "%Y-%m-%d %H:%M:%S")
# rpi1 <- rpi1[order(rpi1$timestamp),]
# 
# select <- df$URI == 3
# rpi3 <- df[select, ]
# rpi3 <- rpi3[1:7]
# rpi3 <- rpi3[complete.cases(rpi3),]
# rpi3$flux <- as.numeric(rpi3$flux)
# rpi3$timestamp <- as.POSIXct(rpi3$timestamp, format = "%Y-%m-%d %H:%M:%S")
# rpi3 <- rpi3[order(rpi3$timestamp), ]


################################################################################################


http <- "https://3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix.cloudant.com/clemson_data/_all_docs?include_docs=true"
httpResponse <- GET(http, authenticate(username, password))
cat(file = stderr(), "Done recieveing data from cloudant\n")

documents <- fromJSON(toString(content(httpResponse, as = "text" , encoding = "UTF-8")))
data <- documents[['rows']]
df <- data[['doc']]

#select columns to be used an rename them. (leave our columns xcoor and ycoor)
df <- data.frame("id" = df$`_id`, 
                 "rev" = df$`_rev`, 
                 "lat" = df$lat, 
                 "lng" = df$lng,
                 "flux" = df$flux,
                 "URI" = df$URI,
                 "time" = df$timestamp)


# remove incomplete rows from the data frame
# ignore missing URIs for the moment
df <- df[complete.cases(df),]

#convert flux values to numbers
df$flux <- as.numeric(df$flux)

# remove rows with invalid coordinates from the dataframe, don't know why these lines have to be seperate
df <- df[(df$lat >= -90.0), ]
df <- df[(df$lat <= 90.00), ]
df <- df[(df$lng >= -180.0), ]
df <- df[(df$lng <= 180.0), ]

# make a vector with unique coordinates contained in df
ucoors <- data.frame(lat=df$lat, lng=df$lng) %>% unique()

#conver time from char vector to POSIXct type 
df$time <- strptime(df$time, format = "%Y-%m-%d %H:%M:%S", tz = "GMT")
df$time <- as.POSIXct(df$time)

# remove any newly-incomplete rows
df <- df[complete.cases(df), ]

URIS <- df$URI %>% unique()
rpi = list()
for(value in URIS){
  rpi[[value]] <- df[df$URI == value, ]
}
