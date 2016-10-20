#' Grabs the Ameriflux Level2 data from the ORNL site and compiles it into one
#' easy to use file.
#'
#' (future versions will include Level3)
#'
#' @param site: Amerflux site abbreviation, can be vector of multiple sites
#' @param gaps: download the gap filled or non gap filled product
#' (default is TRUE, allow no gaps)
#' @keywords Ameriflux, sites, data
#' @export
#' @examples
#' # with defaults, outputting a data frame
#' df <- download.ameriflux(site="US-Ha1",gaps=FALSE)

download.ameriflux = function(site="US-Ha1",gap_fill=TRUE){

  # libraries
  require(data.table) # loads data far faster than read.table()
  require(RCurl) # for fast ftp directory listing

  # grab the OS info
  OS = Sys.info()[1]

  # set timeout of downloads
  options(timeout=300)

  # set server location -- used for windows downloads
  server="ftp://cdiac.ornl.gov/pub/ameriflux/data/Level2/Sites_ByID"

  # loop over all sites
  # download a list of all files to download
  for (i in site){

    # check available products
    url = sprintf("%s/%s/",server,i)
    status = try(getURL(url,dirlistonly = TRUE))

    if(!inherits(status,"try-error")){

      # check what product directories are there
      with_gaps = any(grepl("with_gaps",status))
      gap_filled = any(grepl("gap_filled",status))

      if( gap_filled == FALSE & gap_fill == TRUE){
        warning(sprintf("site %s exists, but does not contain valid gap filled data!",i))
        next
      }

    }else{

      # if the site doesn't exist, either stop if it's the last site
      # otherwise proceed to next one
      warning(sprintf("site %s does not exist, or system timeout!",i))

      # if not the last site, skip to next
      if (i == site[length(site)]){
        stop('last site, exiting')
      }else{
        next # progress to next file
      }

    }

    # set gap strings to be used later on
    if(gap_fill==TRUE){
      gap_dir ="gap_filled"
      gap = "GF"
    }else{
      gap_dir = "with_gaps"
      gap = "WG"
    }

    # download file list for a given site and product (gap filled or not)
	if (i=='US-UMB'){
      url = sprintf("%s/%s/%s/%s/",server,i,gap_dir,'half_hourly')
    }else{
      url = sprintf("%s/%s/%s/",server,i,gap_dir)
    }
    status = try(getURL(url,dirlistonly = TRUE))

    if (!inherits(status,"try-error")){

      flux_data_files = unlist(strsplit(status,"\n"))
      flux_data_files = gsub("\r","",flux_data_files)

      # only select csv ones
      flux_data_files = flux_data_files[grepl("*.csv",flux_data_files)]

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

      # provide some feedback to the CLI
      cat(sprintf("Compiling data for site: %s \n",i))

      for(f in 1:length(flux_data_files)){

        # format url of download file
		if (i=='US-UMB'){
		  url = sprintf("%s/%s/%s/%s/%s",server,i,gap_dir,'half_hourly',flux_data_files[f])
		}else{
		  url = sprintf("%s/%s/%s/%s",server,i,gap_dir,flux_data_files[f])
		}

        # give some feedback on processing
        cat(sprintf("  - adding year: %s \n", years[f]))

        # if it's the first file in the series use it's header as the
        # new file header
        if(f==1){ # downloading first file and writing header and data

          # suppress warnings as it throws unnecessary warnings
          # messing up the feedback to the CLI
          header = suppressWarnings(readLines(url(url),n=20))

          # directly read data from the server into data.table
          data = suppressWarnings(fread(url,skip=20,header=FALSE,sep=",",showProgress=FALSE))

        }else{ # appending the data to an existing file
          tmp = suppressWarnings(fread(url,skip=20,header=FALSE,sep=",",showProgress=FALSE))
          data = rbind(data,tmp)
        }
      }

      # writing the final data frame to file, retaining the original header
      write.table(header,filename,quote=FALSE,row.names=FALSE,col.names=FALSE,sep="")
      write.table(data,filename,quote=FALSE,row.names=FALSE,col.names=FALSE,sep=",",append = TRUE)

    }else{

      print("there is no data at the following location:")
      print(url)
      next

    } # for loop, looping across all the flux data file, if data does not exists or fails to download, skip
  } # for loop, looping over all sites, if there are multiple sites
} # function end
