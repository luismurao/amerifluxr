#' Calculates the optimal span for a loess spline
#' smoother based upon the bayesian information
#' criterion (BIC).
#' 
#' @param y: a vector with measurement values to smooth
#' @param x: a vector with dates / time steps
#' @param weights: optional values to weigh the loess fit with
#' @param step: span increment size
#' @keywords smoother, span, loess, time series
#' @export
#' @examples
#' span <- optimal.span(y)
#' 
#' # dates need to be converted to standard notation using
#' as.Date(my_dates)

# This function takes a data frame with smoothed gcc
# values and CI as input, this data is generated by
# the smooth.ts() routine

optimal.span = function(y,x=NULL, weights=NULL,step=0.01){
  
  # custom BIC function which accepts loess regressions
  myBIC = function(x){
    
    # get the number of observations, residuals
    # and number of parameters needed in the 
    # BIC calculation
    obs = x$n
    res = x$residuals
    params = x$enp
    
    # calculate the BIC
    y = obs * log(mean(res^2)) + (params * log(obs))
    return(y)
  }
  
  # fill x
  if (is.null(x)){
    x = c(1:length(y))
  }
  
  # return BIC for a loess function with a given span
  loessBIC = function(span){
    # check if there are weights, if so use them
    if ( is.null(weights) ){
      fit = suppressWarnings(try(loess(y ~ as.numeric(x),span=span),silent=TRUE))
    }else{
      fit = suppressWarnings(try(loess(y ~ as.numeric(x),span=span, weights = weights),silent=TRUE))
    }
    
    # check if the fit failed if so return NA
    if (inherits(fit,"try-error")){
      return(NA)
    }else{
      return(myBIC(fit))
    }
  }
  
  # parameter range
  span = seq(0.001,1,by=step)
  
  # temporary BIC matrix, lapply loop 
  # (instead of for loop) cleaner syntax
  tmp = unlist(lapply(span,loessBIC))

  # select the span corresponding to the BIC minimum
  optimal.span = span[which(tmp == min(tmp,na.rm=T))[1]]
  
  # return the optimal span
  return(optimal.span)
}