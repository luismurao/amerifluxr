# Start the AmerifluxR shiny interface
#' @keywords GUI
#' @export
#' @examples
#' # outputting TRUE or FALSE
#' ameriflux_explorer()

ameriflux_explorer <- function(){
  appDir = sprintf("%s/R/inst/shiny/ameriflux_explorer",path.package("amerifluxr"))
  shiny::runApp(appDir, display.mode = "normal",launch.browser=TRUE)
}