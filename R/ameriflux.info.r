#' Grabs the ameriflux site table from the LBL site.
#' 
#' @param url: Location of the Ameriflux site table
#' (hopefully will not change to often, default is ok for now)
#' @param path: location of the phantomjs binary (system specific)
#' @keywords Ameriflux, sites, locations, web scraping
#' @export
#' @examples
#' # with defaults, outputting a data frame
#' df <- ameriflux.info()
#' [requires the rvest package for post-processing]
#' http://phantomjs.org/download.html

ameriflux.info <- function(url="http://ameriflux.lbl.gov/sites/site-list-and-pages/",path=NULL){
  
  # read the required libraries
  require(rvest)
  require(RCurl)
  
  # grab the OS info
  OS = Sys.info()[1]
  machine = Sys.info()[4]
  
  # grab the location of the package, assuming it is installed
  # in the user space (not globally)
  phantomjs_path = sprintf("%s/phantomjs/",path.package("amerifluxr"))
  
  # run local code if debugging
  if (machine == "squeeze" | machine == "Pandora.local"){
      phantomjs_path = "~/Dropbox/Research_Projects/code_repository/bitbucket/amerifluxr/inst/phantomjs/"
  }
  
  # subroutines for triming leading spaces
  # and converting factors to numeric
  trim.leading <- function (x)  sub("^\\s+", "", x)
  as.numeric.factor <- function(x) {as.numeric(levels(x))[x]}
  
  # write out a script phantomjs can process
  # change timeout if the page bounces, seems empty !!!
  writeLines(sprintf("var page = require('webpage').create();
                     page.open('%s', function (status) {
                     if (status !== 'success') {
                     console.log('Unable to load the address!');
                     phantom.exit();
                     } else {
                     window.setTimeout(function () {
                     console.log(page.content);
                     phantom.exit();
                     }, 3000); // Change timeout to render the page
                     }
                     });", url), con="scrape.js")
  
  # run different versions of phantomjs depending on the OS
  if (OS == "Linux"){
    # process the script with phantomjs / scrapes zooniverse page
    system(sprintf("%s./phantomjs_linux scrape.js > scrape.html",phantomjs_path),wait=TRUE)
  } else if (OS == "Windows") {
    # process the script with phantomjs / scrapes zooniverse page
    shell(sprintf("%sphantomjs.exe scrape.js > scrape.html",phantomjs_path))
  }else{
    # process the script with phantomjs / scrapes zooniverse page
    system(sprintf("%s./phantomjs_osx scrape.js > scrape.html",phantomjs_path),wait=TRUE)
  }
  
  # load html data
  main = read_html("scrape.html")
  
  # set html element selector for the header
  sel_header = 'thead'
  
  # Extract the header data from the html file
  header = html_nodes(main,sel_header) %>% html_text()
  header = unlist(strsplit(header,"\\n"))
  header = unlist(lapply(header,trim.leading))
  header = header[-which(header == "")]
  
  # set html element selector for the table
  sel_data = 'td'
  
  # process the html file and extract stats
  data = html_nodes(main,sel_data) %>% html_text()
  data = matrix(data,length(data)/length(header),length(header),byrow=TRUE)
  df = data.frame(data)
  header = gsub("\\r","",header) # fix for windows bug
  colnames(df) = tolower(header)
  
  # reformat variables into correct formats (not strings)
  # this is ugly, needs cleaning up
  df$site_id = as.character(df$site_id)
  df$site_name = as.character(df$site_name)
  df$tower_began= as.numeric.factor(df$tower_began)
  df$tower_end = as.numeric.factor(df$tower_end)
  df$location_lat = as.numeric.factor(df$location_lat)
  df$location_long = as.numeric.factor(df$location_long)
  df$location_elev = as.numeric.factor(df$location_elev)
  df$mat = as.numeric.factor(df$mat)
  df$map = as.numeric.factor(df$map)
  df$climate_koeppen = as.character(df$climate_koeppen)
  
  # drop double entries
  df = unique(df)
  
  # drop first row (empty)
  df = df[-1,]
  
  # set row names
  rownames(df) = 1:dim(df)[1]
  
  # fill in the end years on the assumption that
  # where there is a start year but no end year (NA)
  # the measurements are still ongoing
  df$tower_end = as.vector(apply(df,1,function(x,...){
    if(!is.na(x[3]) & is.na(x[4]) ){
        return(as.numeric(format(Sys.time(), "%Y")))
      }else{
        as.numeric(x[4])
      }
    }))
  
  # now we have a proper end date, calculate the site years
  # assume same ending year is a full season (hence + 1)
  df$site_years = (df$tower_end - df$tower_began) + 1
  
  # fill empty climate slots with NA
  df$climate_koeppen[which(df$climate_koeppen == "")] = NA
  
  # create a row of sites which have data (exist on the ftp server)
  # and which don't. I use downloader instead of rvest as I don't trust
  # the layout to be stable enough to use rvest. string matching is
  # robuster than using rvest (at the expense of a temporary file)
  url = try(getURL("ftp://cdiac.ornl.gov/pub/ameriflux/data/Level2/Sites_ByID/",dirlistonly = TRUE) )
  
  # if the download was succesful proceed
  if (!inherits(url,"try-error")){
    sites = unlist(strsplit(url,"\n"))
    sites = gsub("\r","",sites)
    
    # cross reference sites with the metadata table
    df$online_data = rep("no",length(df$site_id))
    df$online_data[which(df$site_id %in% sites)] = "yes"
  }
  
  # remove temporary html file and javascript
  file.remove("scrape.html")
  file.remove("scrape.js")
  
  if (is.null(path)){
    # return data frame
    return(df)  
  }else{
    # write to file
    write.table(df,path,col.names=TRUE,row.names=FALSE,quote=FALSE,sep="|")
  }
}