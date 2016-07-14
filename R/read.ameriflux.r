#' Read an Ameriflux data file (standard format)
#' 
#' @param df: Amerflux data file
#' @keywords Ameriflux, data
#' @export
#' @examples
#' # with defaults, outputting a data frame
#' df <- read.ameriflux(df="AMF_BR-Sa1_2002_2011_L2_GF.txt")

read.ameriflux = function(df){
  
  # load data tables
  require(data.table)
  
  # check if the file exists
  if ( !file.exists(df) ){
    stop("File does not exist")
  }
  
  # pluck real header from the phenocam file
  header = fread(df,skip=16,nrows=1,header=FALSE,sep=",")
  
  # read the data
  df = fread(df,skip=20,header=FALSE,sep=",")
  colnames(df)=as.character(header)
  
  # set all -9999 / -6999 values to NA
  df[df == -9999] = NA
  df[df == -6999] = NA
  
  # return data frame
  return(df)
}