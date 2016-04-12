library(shiny)
library(httr)
library(jsonlite)
library(leaflet)
library(ggplot2)

ui <- fluidPage(
  titlePanel("Super Solar Data Dashboard!"),
  
  fluidRow(
    column(5, wellPanel(
      dateInput("date",
                     label = "Enter Date Range")
    )),
    
    # dynamic input for sensor locations
    column(2, wellPanel(
      uiOutput("locationSelect")
    ))
  ),
  
 
  # sliderInput("hours", 
  #             label = "Hours",
  #             min = 0,
  #             max = 24,
  #             value = c(0, 24)
  # ),
  
  fluidRow(
    column(3, wellPanel(
      actionButton("update", 
                   label = "Apply changes")
      
    )),
    
    column(2, wellPanel(
      selectInput("start_hour", 
                  label = "Start Hour",
                  choices = 0:23)
    )),
    
    column(2, wellPanel(
      selectInput("end_hour",
                  label = "End Hour",
                  choices = 0:23)
    ))
  ),
  
  plotOutput("plot"),
  
  leafletOutput("mymap")
)

# Pull data outside of server... see what happens

username <- "3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix"
password <- "70d0f1455b7dd050452faa5d3650f0907bb98cde87f61fcde0cf57dbca8e3d7e"
#http <- "https://3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix.cloudant.com/clemson_data/_all_docs?limit=1000&include_docs=true&descending=true"
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


server <- function(input, output) {
  
  v <- reactiveValues(active_data = df)
  
  observeEvent(input$update, {
    date <- as.POSIXct(input$date)
    time_range = c()
    time_range[1] <- date + (as.numeric(input$start_hour) * 3600)
    time_range[2] <- date + (as.numeric(input$end_hour) * 3600)
    
    select <- df$URI %in% input$locations
    temp_data <- df[select, ]
    
    temp_data <- temp_data[(temp_data$time > time_range[1] & temp_data$time < time_range[2]),]
    v$active_data <- temp_data
  })
  
  output$plot <- renderPlot({
      # ggplot(aes(x = v$active_data$time, y = v$active_data$flux), data = v$active_data) +
      # geom_point() +
      # xlab("Time") +
      # ylab("Flux Value")
    qplot(x = time, y = flux, data = v$active_data, color = as.factor(URI), geom = "point")
  })
  
  output$mymap <- renderLeaflet(
    # looks like jon mixed up the latitudes and longitudes
    leaflet() %>% 
      addTiles() %>% 
      addMarkers(lat = ucoors$lat, lng = ucoors$lng)
  )
  
  output$locationSelect <- renderUI({
    checkboxGroupInput("locations", 
                label = "Sensors", 
                #choices = 1:length(ucoors$lat))
                choices = df$URI %>% unique(), 
                selected = df$URI %>% unique())
  })
  
}

shinyApp(ui = ui, server = server)