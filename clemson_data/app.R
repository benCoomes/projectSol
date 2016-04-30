library(shiny)
library(httr)
library(jsonlite)
library(leaflet)
library(ggplot2)
library(scales)

ui <- fluidPage(
  fluidRow(column(width = 1, tags$img(width = "90%", height = "90%", src = "paw.png")),
           column(width = 11, titlePanel("Project Sol: Dashboard"))
  ),
  
  tags$hr(),
  
  fluidRow(
    column(width = 6, wellPanel(
      dateRangeInput("dates", label = "Date Range"),
      sliderInput("hours", label = "Hours", min = 0, max = 24, value = c(0, 24)),
      uiOutput("locationSelect"),
      actionButton("update", label = "Apply Changes"),
      tags$hr(),
      radioButtons("yscale", label = "Y axis scale", choices = c("Linear", "Logrithmic"), inline = TRUE))
    ), 
    column(width = 6, leafletOutput("mymap"))
  ), 
  
  tags$hr(),
  
  fluidRow(
    plotOutput("plot")
  )
)


# Pull data outside of server... see what happens

username <- "3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix"
password <- "70d0f1455b7dd050452faa5d3650f0907bb98cde87f61fcde0cf57dbca8e3d7e"
#http <- "https://3af116fb-a68b-41e3-959b-29d1a83399d9-bluemix.cloudant.com/clemson_data/_all_docs?limit=100&include_docs=true&descending=true"
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
df <- df[complete.cases(df),]

#convert flux from facror to continous
df$flux <- as.numeric(levels(df$flux))[df$flux]


  # remove rows with invalid coordinates from the dataframe, don't know why these lines have to be seperate
  df <- df[(df$lat >= -90.0), ]
  df <- df[(df$lat <= 90.00), ]
  df <- df[(df$lng >= -180.0), ]
  df <- df[(df$lng <= 180.0), ]
  
  # make a vector with unique coordinates contained in df
  ucoors <- data.frame(lat=df$lat, lng=df$lng) %>% unique()
  
  #convert time from char vector to POSIXct type 
  df$time <- strptime(df$time, format = "%Y-%m-%d %H:%M:%S", tz = "GMT")
  df$time <- as.POSIXct(df$time)
  
  
  # remove any newly-incomplete rows
  df <- df[complete.cases(df), ]
  
  #TEMPORARY - remove exreme outliers
  ubound <- sd(df$flux) * 4 + mean(df$flux)
  df <- df[df$flux < ubound, ]


server <- function(input, output) {
  
  v <- reactiveValues(active_data = df)
  
  observeEvent(input$update, {
    dates <- as.POSIXct(input$dates)
    time_range = c()
    time_range[1] <- dates[1] + (as.numeric(input$hours[1]) * 3600)
    time_range[2] <- dates[2] + (as.numeric(input$hours[2] * 3600))
    
    select <- df$URI %in% input$locations
    temp_data <- df[select, ]
    
    temp_data <- temp_data[(temp_data$time > time_range[1] & temp_data$time < time_range[2]),]
    v$active_data <- temp_data
  })
  
  output$plot <- renderPlot({
    if(input$yscale == 'Logrithmic'){
      translation <- log2_trans
    }
    else{
      translation <- identity_trans
    }
    qplot(x = time, y = flux, data = v$active_data, color = as.factor(URI), geom = "point") +
      scale_y_continuous(trans = translation())
  })
  
  output$mymap <- renderLeaflet(
    leaflet() %>% 
      addTiles() %>% 
      addMarkers(lat = ucoors$lat, lng = ucoors$lng)
  )
  
  output$locationSelect <- renderUI({
    checkboxGroupInput("locations", 
                label = "Sensors", 
                choices = df$URI %>% unique(), 
                selected = df$URI %>% unique(), 
                inline = TRUE)
  })
  
}

shinyApp(ui = ui, server = server)