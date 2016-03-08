#' Grabs the ameriflux data from the ORNL site and compiles it into one
#' big file.
#' 
#' @param site: Amerflux site abbreviation, can be vector of multiple sites
#' @param gaps: download the gap filled or non gap filled product
#' (default is TRUE, allow no gaps)
#' @keywords Ameriflux, sites, data
#' @export
#' @examples
#' # with defaults, outputting a data frame
#' df <- download.ameriflux(site="US-Ha1",gaps=FALSE)

download.ameriflux = function(site="US-Ha1",gaps=TRUE){
  
  # libraries
  require(downloader) # to ensure compatibility with Windows systems
  require(data.table) # loads data far faster than read.table()
  require(stringr) # to parse html data easily
  
  # set timeout of downloads
  options(timeout=300)
  
  # set server location -- used for windows downloads
  server="ftp://cdiac.ornl.gov/pub/ameriflux/data/Level2/Sites_ByID"
  
  # loop over all sites
  # download a list of all files to download
  for (i in site){
    
    # check available products
    url = sprintf("%s/%s/",server,i)
    print(url)
    status = try(download(url=url,"site_info.txt",quiet=T,method="curl")) # add exception for Windows?
    
    if(status != 0 ){
      
      # if the site doesn't exist, either stop if it's the last site
      # otherwise proceed to next one
      warning(sprintf("site %s does not exist, or system timeout!",i))
      
      # if not the last site, skip to next
      if (i == site[length(site)]){
        stop('last site, exiting')
      }else{
        next # progress to next file
      }
      
    }else{
      
      # read in data
      site_info = readLines("site_info.txt")
      with_gaps = any(grepl("with_gaps",site_info))
      gap_filled = any(grepl("gap_filled",site_info))
      
      if( gap_filled == FALSE & with_gaps == FALSE){
        warning(sprintf("site %s exists, but does not contain valid data!",i))
        next
      }
    }
    
    # set gap strings to be used later on
    if(gaps==TRUE){
      
      gap_dir = "with_gaps"
      gap = "WG"      
      
    }else{
      
      gap_dir ="gap_filled"
      gap = "GF"
      
    }
    
    # remove old file / just to be sure not to read in faulty data
    if(file.exists('site_files.txt')){
       file.remove('site_files.txt')
    }
    
    # download file list for a given site and product (gap filled or not)
    url = sprintf("%s/%s/%s/",server,i,gap_dir)
    status = try(download(url=url,"site_files.txt",quiet=T,method="curl"))
    
    if (status == 0){
      
      flux_data_files = read.table("site_files.txt")[,9]
      flux_data_files = as.character(flux_data_files[grep("*.csv",flux_data_files)])
 
      # grab start and end year
      years = unique(unlist(lapply(strsplit(flux_data_files,split="_"),"[[",3)))
      start_year = min(years)
      end_year = max(years)
      
      # format the final filename
      filename = sprintf("AMF_%s_%s_%s_L2_%s.txt",i,start_year,end_year,gap)

      # remove old file / just to be sure not to read in faulty data
      if(file.exists(filename)){
        file.remove(filename)
      }
      
      cat(sprintf("Compiling data for site: %s \n",i))
      
      for(f in 1:length(flux_data_files)){
        
        # format url of download file
        url = sprintf("%s/%s/%s/%s",server,i,gap_dir,flux_data_files[f])
        # give some feedback on processing
        cat(sprintf("  - adding year: %s \n", years[f]))
        
        # if it's the first file in the series use it's header as the
        # new file header
        if(f==1){ # downloading first file and writing header and data
          
          download(url=url,"flux_data.txt",quiet=T,method="curl") # add exception for Windows?
          header = readLines("flux_data.txt",n=20)
          data = fread("flux_data.txt",skip=20,header=FALSE,sep=",")
          write.table(header,filename,quote=FALSE,row.names=FALSE,col.names=FALSE,sep="")
          write.table(data,filename,quote=FALSE,row.names=FALSE,col.names=FALSE,sep=",",append = TRUE)
          
        }else{ # appending the data to the existing file
          
          download(url=url,"flux_data.txt",quiet=T,method="curl") # add exception for Windows?
          data = fread("flux_data.txt",skip=20,header=FALSE,sep=",")
          write.table(data,filename,quote=FALSE,row.names=FALSE,col.names=FALSE,sep=",",append = TRUE)          
          
        }  
      }
      
      # clean up all temporary download files
      file.remove("site_info.txt")  # remove the site info (test if the site exists)
      file.remove("site_files.txt") # remove the list of files for each site
      file.remove("flux_data.txt")  # remove the temporary flux data file
      
    }else{
      
      print("there is no data at the following location:")
      print(url)
      next
      
    } # for loop, looping across all the flux data file, if data does not exists or fails to download, skip
  } # for loop, looping over all sites, if there are multiple sites
} # function end