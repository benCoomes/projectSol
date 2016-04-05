library(shiny)
library(httr)
library(jsonlite)
library(leaflet)
library(ggplot2)

ui <- fluidPage(
  numericInput("count", 
               label = "Number of data Points",
               value = 50,
               min = 0,
               step = 10),
  
  actionButton("update", 
               label = "Apply changes"),
  
  plotOutput("plot"),
  
  leafletOutput("mymap")
)

server <- function(input, output) {
  
  username <- "3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix"
  password <- "70d0f1455b7dd050452faa5d3650f0907bb98cde87f61fcde0cf57dbca8e3d7e"
  
  rawDataFrame <-  {
    #http <- "https://3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix.cloudant.com/clemson_data/_all_docs?limit=100&include_docs=true&descending=true"
    http <- "https://3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix.cloudant.com/clemson_data/_all_docs?include_docs=true"
    httpResponse <- GET(http, authenticate(username, password))
    cat(file = stderr(), "Done recieveing data from cloudant\n")
    
    documents <- fromJSON(toString(content(httpResponse, as = "text" , encoding = "UTF-8")))
    data <- documents[['rows']]
    df <- data[['doc']]
    
    # compose vectors into data frame
    colnames(df) <- c("id", "rev", "flux", "lat", "lng", "time")
    
    # remove incomplete rows from the data frame
    df <- df[complete.cases(df), ]
    
    #convert flux values to numbers
    df$flux <- as.numeric(df$flux)
    
    # remove rows with invalid coordinates from the dataframe, don't know why these have to be seperate
    df <- df[(df$lat >= -90.0), ]
    df <- df[(df$lat <= 90.00), ]
    df <- df[(df$lng >= -180.0), ]
    df <- df[(df$lng <= 180.0), ]
    
    # make a vector with unique coordinates contained in df
    ucoors <- data.frame(lat=df$lat, lng=df$lng) %>% unique()
    
    #conver time from char vector to POSIXct type 
    df$time <- strptime(df$time, format = "%Y-%m-%d %H:%M:%S")
    df$time <- as.POSIXct(df$time)
    ordereddf <- df[order(df$time),]
  } 
  
  v <- reactiveValues(active_data = df)
  
  observeEvent(input$update, {
    v$active_data <- df[1:input$count,]
  })
  
  output$plot <- renderPlot({
      ggplot(aes(x = v$active_data$time, y = v$active_data$flux), data = v$active_data) +
      geom_point() +
      xlab("Time") +
      ylab("Flux Value")
  })
  
  output$mymap <- renderLeaflet(
    # looks like jon mixed up the latitudes and longitudes
    leaflet() %>% 
      addTiles() %>% 
      addMarkers(lat = ucoors[["lng"]][1], lng = ucoors[["lat"]][1])
  )
  
}

shinyApp(ui = ui, server = server)