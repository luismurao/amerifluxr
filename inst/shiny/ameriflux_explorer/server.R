# load required libraries
require(shiny) # GUI components
require(shinydashboard) # GUI components
require(leaflet) # mapping utility
require(plotly) # fancy ploty in shiny
require(DT) # interactive tables for shiny
require(data.table) # loads data far faster than read.table()

# grab the OS info
OS = Sys.info()[1]
machine = Sys.info()[4]

# When on the machine of the developer, sideload the code locally
# for quick reviewing of changes to the GUI
if (machine == "squeeze" | machine == "razor"){
  source('~/Dropbox/Research_Projects/code_repository/bitbucket/amerifluxr/R/download.ameriflux.r')
  source('~/Dropbox/Research_Projects/code_repository/bitbucket/amerifluxr/R/dir.exists.r')
  source('~/Dropbox/Research_Projects/code_repository/bitbucket/amerifluxr/R/ameriflux.info.r')
  source('~/Dropbox/Research_Projects/code_repository/bitbucket/amerifluxr/R/aggregate.flux.r')
}

# create temporary directory and move into it
if (!dir.exists("~/ameriflux_cache")){
  dir.create("~/ameriflux_cache")
}

# set the base directory to the cache directory
# this prevents any temporary files interfering with
# local data
setwd("~/ameriflux_cache")

# grab the latest site information from the Ameriflux site.
# use the metadata file if present and not older than 1 year!
if (!file.exists("ameriflux_metadata.txt")){
  ameriflux.info() 
}

# grab the file info from the metadata file and compare
# to current year, if creation year and current year is
# the same - do not update
m_time = file.info("ameriflux_metadata.txt")$mtime
m_year = format(as.Date(m_time),"%Y") # get modification year
c_year = format(Sys.Date(),"%Y")

# check years
if(m_year != c_year){
  ameriflux.info()
}

# finally read in the metadata if all checks are go
# convert to data frame instead of data table for subsetting
# will change to data table later == faster
df = as.data.frame(fread("ameriflux_metadata.txt",header=TRUE,sep="|"))

# create a character field with html to call as marker
# popup. This includes a thumbnail of the site!
df$preview <- apply(df,1,function(x)paste(
  "<table width=200px, border=0px>",
  "<tr>",
  "<td><b>",
  x[1],
  "</b></td>",
  "</tr>",
  
  "<tr>",
  "<td>",
  x[2],
  "</td>",
  "</tr>",
  
  "<tr>",
  "<td>",
  "Annual precip.:",x[11]," mm",
  "</td>",
  "</tr>",
  
  "<tr>",
  "<td>",
  "Mean Annual Temp.:",x[10]," C",
  "</td>",
  "</tr>",
  
  "<tr>",
  "<td>",
  "Online Data:",x[13],
  "</td>",
  "</tr>",
  
  "</table>",sep=""))

# start server routine
server <- function(input, output, session){
  
  # Reactive expression for the data subsetted
  # to what the user selected
  v1 <- reactiveValues()
  v2 <- reactiveValues()
  reset <- reactiveValues()
  row_clicked <-reactiveValues()
  
  # function to subset the site list based upon coordinate locations
  filteredData <- function(){
    if (!is.null(isolate(v2$lat))) {
      if (input$colors=="ALL"){
        tmp = df[which(df$location_lat < isolate(v1$lat) & df$location_lat > isolate(v2$lat) & df$location_long > isolate(v1$lon) & df$location_long < isolate(v2$lon)),]
        unique(tmp)
      }else{
        df[which(df$location_lat < isolate(v1$lat) & df$location_lat > isolate(v2$lat) & df$location_long > isolate(v1$lon) & df$location_long < isolate(v2$lon) & df$igbp == input$colors),]
      }
    }else{
      if (input$colors=="ALL"){
        unique(df)
      }else{
        df[df$igbp == input$colors,]
      }
    }
  }
  
  getValueData = function(table){
    
    nr_sites = length(unique(table$site_id))
    output$site_count <- renderInfoBox({
      valueBox(nr_sites,"Sites",
               icon = icon("list"),
               color = "blue")
    })
    
    nr_years = sum(table$site_years,na.rm=T)
    output$year_count <- renderInfoBox({
      valueBox(nr_years,"Site Years",
               icon = icon("list"),
               color = "blue")
    })
    
    output$season_count <- renderInfoBox({
      valueBox(nr_sites,"# Growing Seaons",
               icon = icon("list"),
               color = "blue")
    })
    
  }
  
  # Use leaflet() here, and only include aspects of the map that
  # won't need to change dynamically (at least, not unless the
  # entire map is being torn down and recreated).
  output$map <- renderLeaflet({  
    map = leaflet(df) %>%
      addTiles("http://otile3.mqcdn.com/tiles/1.0.0/sat/{z}/{x}/{y}.jpg",
               attribution='Tiles Courtesy of <a href="http://www.mapquest.com/">MapQuest</a> &mdash; Portions Courtesy NASA/JPL-Caltech and U.S. Depart. of Agriculture, Farm Service Agency',
               group = "JPL") %>%
      addProviderTiles("OpenStreetMap.BlackAndWhite",group = "OSM") %>%
      addMarkers(lat = ~location_lat,lng = ~location_long,popup=~preview) %>%
      # Layers control
      addLayersControl(
        baseGroups = c("OSM", "JPL"),
        position = c("topleft"),
        options = layersControlOptions(collapsed = TRUE)
      ) %>%
      setView(lng = -66, lat = 45, zoom = 2)
  })
  
  # Incremental changes to the map. Each independent set of things that can change
  # should be managed in its own observer.
  observe({
    leafletProxy("map", data = filteredData()) %>%
      clearMarkers() %>%
      addMarkers(lat = ~location_lat,lng = ~location_long,popup=~preview)
    
    # update the data table in the explorer
    output$table <- DT::renderDataTable({
      tmp = filteredData()[,-c(2,14)] # drop last column
      return(tmp) },
      selection="single",
      options = list(lengthMenu = list(c(5,10), c('5','10')),pom=list('location_long')), 
      extensions = 'Responsive'
    )
    
    # update value box
    getValueData(filteredData())
    
    # update the climatology plot
    output$test <- renderPlot({
      par(mar=c(4,4,1,1))
      plot(map~mat,data=filteredData(),
           xlab=expression("MAT ("*degree*"C)"),
           ylab="MAP (mm)",
           pch=19,
           col=rgb(0.5,0.5,0.5,0.3),
           xlim=c(-15,30),
           ylim=c(0,3000)
      )
    },height = function() {
      session$clientData$output_test_height
    })
  })
  
  # grab the bounding box, by clicking the map
  observeEvent(input$map_click, {
    # if clicked once reset the bounding box
    # and show all data
    if (!is.null(isolate(v2$lat))) {
      
      # set bounding box values to NULL
      v1$lat = NULL; v2$lat = NULL; v1$lon = NULL; v2$lon = NULL
      
      leafletProxy("map", data = filteredData()) %>%
        clearMarkers() %>%
        clearShapes() %>%
        addMarkers(lat = ~location_lat,lng = ~location_long,popup=~preview)
      
      getValueData(filteredData())
      
      # update the climatology plot
      output$test <- renderPlot({
        par(mar=c(4,4,1,1))
        plot(map~mat,data=filteredData(),
             xlab=expression("MAT ("*degree*"C)"),
             ylab="MAP (mm)",
             pch=19,
             col=rgb(0.5,0.5,0.5,0.3),
             xlim=c(-15,30),
             ylim=c(0,3000)
        )
      },height = function() {
        session$clientData$output_test_height
      })
      
    }else{
      # grab bounding box coordinates
      # TODO: validate the topleft / bottom right order
      if (!is.null(isolate(v1$lat))) {
        v2$lat <- input$map_click$lat
        v2$lon <- input$map_click$lng
      }else{
        v1$lat <- input$map_click$lat
        v1$lon <- input$map_click$lng
        leafletProxy("map", data = filteredData()) %>%
          clearMarkers() %>% 
          addMarkers(lat = ~location_lat,lng = ~location_long,popup=~preview)%>%
        addCircleMarkers(lng=isolate(v1$lon),lat=isolate(v1$lat),color="red",radius=3,fillOpacity=1,stroke=FALSE)
      }
    }
    
    # if the bottom right does exist
    if (!is.null(isolate(v2$lat))) {
      
      # subset data based upon topleft / bottomright
      tmp = filteredData()
      
      # check if the dataset is not empty
      if( dim(tmp)[1]!=0 ){
        
        # update the map
        leafletProxy("map", data = tmp) %>%
          clearMarkers() %>% 
          addMarkers(lat = ~location_lat,lng = ~location_long,popup=~preview) %>%
          addRectangles(
            lng1=isolate(v1$lon), lat1=isolate(v1$lat),
            lng2=isolate(v2$lon), lat2=isolate(v2$lat),
            fillColor = "transparent",
            color="grey")
        
        # update the data table in the explorer
        output$table <- DT::renderDataTable({
          tmp = filteredData()[,-c(2:14)]
          return(tmp) },
          selection="single",
          options = list(lengthMenu = list(c(5,10), c('5','10')),pom=list('location_long')), 
          extensions = c('Responsive')
        )
        
        # update the value box
        getValueData(filteredData())
        
        # update the climatology plot
        output$test <- renderPlot({
          par(mar=c(4,4,1,1))
          plot(map~mat,data=filteredData(),
               xlab=expression("MAT ("*degree*"C)"),
               ylab="MAP (mm)",
               pch=19,
               col=rgb(0.5,0.5,0.5,0.3),
               xlim=c(-15,30),
               ylim=c(0,3000)
          )
        },height = function() {
          session$clientData$output_test_height
        })
        
      }else{
        # set bounding box values to NULL
        v1$lat = NULL; v2$lat = NULL; v1$lon = NULL; v2$lon = NULL
        
        leafletProxy("map", data = filteredData()) %>%
          clearMarkers() %>%
          clearShapes() %>%
          addMarkers(lat = ~location_lat,lng = ~location_long,popup=~preview)
        
        # update the climatology plot
        output$test <- renderPlot({
          par(mar=c(4,4,1,1))
          plot(map~mat,data=filteredData(),
               xlab=expression("MAT ("*degree*"C)"),
               ylab="MAP (mm)",
               pch=19,
               col=rgb(0.5,0.5,0.5,0.3),
               xlim=c(-15,30),
               ylim=c(0,3000)
          )
        },height = function() {
          session$clientData$output_test_height
        })
      }
    }
  })
  
  downloadData <- function(myrow,gaps,refresh){
    
    # if nothing is selected return NULL
    if (length(myrow)==0){
      return(NULL)
    }
    
    # if there is a site selected but it does not have data online
    # return NULL as well
    if (df$online_data[as.numeric(myrow)] == "no"){
      return(NULL)
    }
    
    # convert binary gap filling values to text
    if (gaps == FALSE){
      gaps_label = "WG"
    }else{
      gaps_label = "GF"
    }
    
    # grab the necessary parameters to download the site data
    site = df$site_id[as.numeric(myrow)]
    
    # Create a Progress object
    progress <- shiny::Progress$new()
    
    # Make sure it closes when we exit this reactive, even if there's an error
    on.exit(progress$close())
    
    # download data message
    progress$set(message = "Status:", value = 0)
    progress$set(value = 0.3,detail = "Downloading Ameriflux data")
    
    # download phenocam data from the server
    # first formulate a url, then download all data
    
    # check if previously downloaded data exists and load these
    # instead of reprocessing
    status = list.files(getwd(),pattern=sprintf("^AMF_%s_.*_%s\\.txt$",site,gaps_label))[1]
    
    # if the file does not exist, download it
    if (is.na(status)){
        status = try(download.ameriflux(site = site,gap_fill=gaps))
    }
    
    # if refresh is TRUE, force the download of the data
    # do not use the data which already resides in the cache directory
    if (refresh){
      status = try(download.ameriflux(site = site,gap_fill=gaps))
    }
    
    # if the download fails, print NULL
    if(inherits(status,"try-error")){
      progress$set(value=0.4,detail = "download error!")
      return(NULL)
    }else{
      
      file = list.files(getwd(),pattern=sprintf("^AMF_%s_.*_%s\\.txt$",site,gaps_label))[1]
      
      # read the data
      header = fread(file,skip=16,nrows=1,header=FALSE,sep=",")
      data = fread(file,skip=20,header=FALSE,sep=",")
      colnames(data)=as.character(header)
      
      # Aggregating to daily values
      progress$set(value=0.5,detail = "aggregating to daily values")
      plot_data = aggregate.flux(data)
      return(plot_data)
    }
  }
  
  # observe the state of the table, if changed update the data
  inputData = reactive({downloadData(as.numeric(input$table_row_last_clicked),input$gap_fill,input$refresh)})
  
  # plot the data 
  output$time_series_plot <- renderPlotly({
    
    # set colours
    labels_covariate_col = "rgb(231,41,138)"
    covariate_col = "rgba(231,41,138,0.4)"
    flux_col = "rgba(102,166,30,0.8)"
    envelope_col = "rgba(128,128,128,0.2)"
    ltm_col = "rgba(128,128,128,0.8)"
    
    # load data
    plot_data = inputData()
    
    if (is.null(plot_data)){
      
      # format x-axis
      ax <- list(
        title = "",
        zeroline = FALSE,
        showline = FALSE,
        showticklabels = FALSE,
        showgrid = FALSE
      )
      p = plot_ly(x = 0, y = 0, text = "NO DATA AVAILABLE - CONTACT SITE PI", mode = "text") %>% layout(xaxis = ax, yaxis = ax)
    }else{
      
      # subset data according to input / for some reason I can't call the
      # data frame columns using their input$... name
      date = plot_data$date
      year = plot_data$year
      doy = plot_data$doy  
      flux = plot_data[,which(colnames(plot_data)==input$productivity)]
      
      if (input$plot_type == "daily"){        
        
        # include cummulative values in plotting, should be easier to interpret
        # the yearly summary plots
        covariate = plot_data[,which(colnames(plot_data)==input$covariate)]
        
        # format y-axis
        ay1 = list(
          title=input$productivity,
          showgrid=FALSE
        )
        
        ay2 <- list(
          tickfont = list(color = labels_covariate_col),
          titlefont=list(color= labels_covariate_col),
          overlaying = "y",
          title = input$covariate,
          side = "right",
          showgrid=FALSE
        )
        
        p = plot_ly(x=date,
                    y=flux,
                    mode="lines",
                    name=input$productivity,
                    line=list(color=flux_col)) %>%
          add_trace(x=date, y = covariate, mode="lines", yaxis = "y2", line=list(color=covariate_col), name = input$covariate) %>%
          layout(xaxis = list(title="Date"), yaxis = ay1, yaxis2 = ay2, showlegend = TRUE,
                 title = df$site_id[as.numeric(input$table_row_last_clicked)])
      }else{
        
          # long term mean flux data
          flux_mean = as.vector(by(flux,INDICES=doy,mean,na.rm=T))
          flux_sd = as.vector(by(flux,INDICES=doy,sd,na.rm=T))
          doy_mean = as.vector(by(doy,INDICES=doy,mean,na.rm=T))
          
          # smoothing this data here is less than ideal,
          # also the fixed span is not optimal but will do for now.
          fit = loess(flux ~ as.numeric(as.Date(date)),span=0.02)
          flux_smooth = predict(fit,as.numeric(as.Date(date)),se=FALSE)
          
          p = plot_ly(x=doy_mean, y = flux_mean, mode="lines",
                      name = "LTM",
                      line=list(color=ltm_col),
                      inherit=FALSE) %>%
          add_trace(x=doy_mean, y = flux_mean - flux_sd, mode = "lines",
                    fill = "none", line=list(width=0,color=envelope_col),
                    showlegend = FALSE, name="SD") %>%
          add_trace(x=doy_mean, y = flux_mean + flux_sd, mode = "lines",
                    fill = "tonexty", line=list(width=0,color=envelope_col),
                    showlegend = TRUE, name="SD") %>%
          add_trace(x=doy,y=flux_smooth,group=year,mode="lines",showlegend = TRUE) %>%
          layout(xaxis = list(title="DOY"), yaxis = list(title=input$productivity),
                 title = df$site_id[as.numeric(input$table_row_last_clicked)])
      }
    }
  })
} # server function end