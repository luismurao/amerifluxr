#' Read an Ameriflux data file (standard format)
#' 
#' @param df: Amerflux data file or data frame
#' @keywords Ameriflux, data
#' @export
#' @examples
#' # with defaults, outputting a data frame
#' df <- read.ameriflux(df="AMF_BR-Sa1_2002_2011_L2_GF.txt")

read.ameriflux = function(df){
  
  # load data tables
  require(data.table)
  
  # pluck real header from the phenocam file
  header = fread(df,skip=16,nrows=1,header=FALSE,sep=",")
  
  # read the data
  df = fread(df,skip=20,header=FALSE,sep=",")
  colnames(df)=as.character(header)
  
  # return data frame
  return(df)
}