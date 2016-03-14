#' return NEE source sink transitions for a daily
#' aggregated file ( agreggate.flux() )
#' 
#' @param df: a daily Amerflux data frame
#' @keywords Ameriflux, data, phenology
#' @export
#' @examples
#' # with defaults, outputting a data frame
#' df <- nee.transitions(df)

nee.transitions = function(df){
  
  # create upper and lower interval
  df$NEE_upper = df$NEE_smooth + (1.96 * df$NEE_se)
  df$NEE_lower = df$NEE_smooth - (1.96 * df$NEE_se)
  
  # function to calculate transitions
  crossing = function(x){
    
    # location of NEE data
    cols = c("NEE_smooth","NEE_upper","NEE_lower")
    
    # create output matrix
    output = matrix(NA,3,3)
    
    # loop over all the smoothed NEE columns
    for (i in 1:length(cols)){
      doy_tmp = x$doy
      nee = x[,which(colnames(x)==cols[i])]
      loc_nee = which(nee>0)
      doy_tmp[loc_nee] = NA
      
      if(any(!is.na(doy_tmp))){
        values = na.contiguous(doy_tmp)
        # calculate the min and max doy
        # for a continuous stretch of 
        # negative values (update)
        doy_min = values[1]
        doy_max = values[length(values)]
      }else{
        next # trap empty years / only NA
      }
      
      # calculate the growing season length
      gsl = doy_max - doy_min
      
      # put everything in the original matrix
      output[i,] = c(doy_min,doy_max,gsl)
    }
    
    # convert to a vector and return
    output = as.vector(output)
    return(output)
  }
  
  # apply crossing to all years
  # and reshape output
  output = by(df,INDICES = df$year,crossing)
  l= length(unlist(output))
  output = matrix(unlist(output),l/9,9,byrow=T)
  output = data.frame(unique(df$year),output)
  
  # find columns that hold NEE_ (smooth) data
  col_names = c("NEE_smooth","NEE_upper","NEE_lower")
  col_names = c(sprintf("SOS_%s",col_names),sprintf("EOS_%s",col_names),sprintf("GSL_%s",col_names))
  colnames(output)=c("year",col_names)
  output = na.omit(output)
  
  # return data
  return(output)
}