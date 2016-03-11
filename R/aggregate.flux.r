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
  
  # constants
  sec_hh = 1800 # seconds in a half hour
  mol_c=12/1000000 # g C per umol CO
  
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
  doy_long = df$DOY
  year_long = df$YEAR
  
  # For reference: Fluxes are averages for the half hour, so to get a per
  # Half-hour flux you need to multiply by 1800.
  # Fluxes on a half hourly or hourly scale are always reported per second, 
  # whilst aggregates are used for longer scales (per day, week etc.)
  GPP = as.vector(by(df$GPP*sec_hh*mol_c,INDICES = list(doy_long,year_long),sum,na.rm=T)) # gC/m2/day
  NEE = as.vector(by(df$NEE*sec_hh*mol_c,INDICES = list(doy_long,year_long),sum,na.rm=T)) # gC/m2/day
  PAR = as.vector(by(df$PAR*sec_hh,INDICES = list(doy_long,year_long),sum,na.rm=T)) # umol/m2/day
  # NOTE: the above values assume no missing data to be realistic! This might not
  # be the case for the raw data. Conversions to gC m-2 d-1 might make more sense as the
  # numbers become large with the 1800 multiplier.
  
  temperature = as.vector(by(df$TA,INDICES = list(doy_long,year_long),mean,na.rm=T)) # degrees C
  VPD = as.vector(by(df$VPD,INDICES = list(doy_long,year_long),mean,na.rm=T)) # kpa
  RH = as.vector(by(df$RH,INDICES = list(doy_long,year_long),mean,na.rm=T)) # %
  precipitation = as.vector(by(df$PREC,INDICES = list(doy_long,year_long),sum,na.rm=T)) # %
  
  # create date vectors as long as the daily aggregates
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