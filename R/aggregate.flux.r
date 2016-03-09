#' Create daily aggregates of select parameters in a
#' standard Ameriflux data file or data frame
#' 
#' @param df: Amerflux data file or data frame
#' @keywords Ameriflux, sites, data
#' @export
#' @examples
#' # with defaults, outputting a data frame
#' df <- aggregate.flux(df="AMF_BR-Sa1_2002_2011_L2_GF.txt")

aggregate.flux = function(df){
  
  # load required libraries
  require(data.table)
  
  # check file format
  # if the data is not a data frame, load
  # the file (assuming it is a phenocam)
  # summary file, otherwise rename the
  # input data to df
  if(!is.data.frame(df)){
    if(file.exists(df)){
      # pluck real header from the phenocam file
      header = fread(df,skip=16,nrows=1,header=FALSE,sep=",")
      df = fread(df,skip=20,header=FALSE,sep=",")
      colnames(df)=as.character(header)
    }else{
      stop('Faulty data file!')
    }
  }
  
  # set NA values
  df[df <= -6999] = NA
  
  # rename the time variables, for convenience
  doy_long = as.integer(floor(df$DTIME))
  year_long = df$YEAR
  
  # check the measurements units, how to convert from mmmol/s / half hour to daily values
  GPP = as.vector(by(df$GPP,INDICES = list(doy_long,year_long),sum,na.rm=T)) # umol/m2/s
  NEE = as.vector(by(df$NEE,INDICES = list(doy_long,year_long),sum,na.rm=T)) # umol/m2/s
  temperature = as.vector(by(df$TA,INDICES = list(doy_long,year_long),mean,na.rm=T)) # degrees C
  PAR = as.vector(by(df$PAR,INDICES = list(doy_long,year_long),sum,na.rm=T)) # umol/m2/s
  VPD = as.vector(by(df$VPD,INDICES = list(doy_long,year_long),mean,na.rm=T)) # kpa
  RH = as.vector(by(df$RH,INDICES = list(doy_long,year_long),mean,na.rm=T)) # %
  precipitation = as.vector(by(df$PREC,INDICES = list(doy_long,year_long),sum,na.rm=T)) # %
  
  # create date vectors
  doy = as.vector(by(doy_long,INDICES = list(doy_long,year_long),max,na.rm=T))
  year = as.vector(by(year_long,INDICES = list(doy_long,year_long),max,na.rm=T))
  date = as.Date(sprintf("%s-%s",year,doy),"%Y-%j")
  
  # compile into data frame and return
  df = data.frame(date,year,doy,GPP,NEE,temperature,PAR,VPD,RH,precipitation)
  
  # drop locations where the year has an na value
  df = df[!is.na(df$year),]
  
  # return data
  return(df)
}