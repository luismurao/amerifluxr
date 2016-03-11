# Start the AmerifluxR shiny interface
#' @keywords GUI
#' @export
#' @examples
#' # outputting TRUE or FALSE
#' ameriflux.gui()

ameriflux.gui <- function(){
  appDir = sprintf("%s/R/inst/shiny/ameriflux_explorer",path.package("amerifluxr"))
  shiny::runApp(appDir, display.mode = "normal",launch.browser=TRUE)
}