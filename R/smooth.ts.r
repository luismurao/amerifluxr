#' Smooths a daily Ameriflux file (NEE/GPP) or data frame using
#' the BCI optimized smoothing parameter
#' 
#' @param df: a Ameriflux data file or data frame
#' @keywords time series, smoothing, Ameriflux
#' @export
#' @examples
#' # with defaults, outputting a data frame
#' # with smoothed values, overwriting the original
#' df <- smooth.ts(df)

smooth.ts <- function(df,value="GPP"){
  
  # load libraries
  require(zoo)
  
  # set colnames string
  c_names=sprintf("%s_%s",rep(value,2), c("smooth","se"))
  
  # if the data is not a data frame, load
  # the file (assuming it is a phenocam)
  # summary file, otherwise rename the
  # input data to df
  if(!is.data.frame(df)){
    if(file.exists(df)){
      # read the original data
      df = read.table(df,header=T,sep=',')
    }else{
      stop("not a valid data frame or file")
    }
  }
  
  # create a data frame and name columns
  # overwrite the original dataframe
  y = df[,which(colnames(df)==value)]
  
  if (length(unique(y)) == 1 | is.na(1)){
    df = matrix(NA,length(y),3)
  }else{
    
  # smooth input series for plotting
  optim.span = optimal.span(y)
  fit = loess(y ~ as.numeric(df$date),span = optim.span)
  fit = predict(fit,as.numeric(df$date),se=TRUE)
  
  # populate the dataframe with the smooth gcc values
  # and the upper and lower CI
  y_smooth = fit$fit
  y_se = fit$se
  
  # max gap is 10 days, to avoid flagging periods where
  # you only lack some data
  int = na.approx(y, maxgap = 10)
  int_flag = rep(0,length(y))
  int_flag[which(is.na(int))] = 1
  
  # put interpolation flag into the data frame
  y_smooth[int_flag==1]=NA
  y_se[int_flag==1]=NA
  
  # put results in a data frame
  df = data.frame(y_smooth,y_se)
  }
  
  # set col names
  colnames(df) = c_names 
  
  # return dataframe
  return(df)
}
