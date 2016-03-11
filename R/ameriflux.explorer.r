#' Start the AmerifluxR shiny interface
#' @param ... none
#' @keywords GUI
#' @export
#' @examples
#' ameriflux.explorer()

ameriflux.explorer <- function(){
  appDir = sprintf("%s/shiny/ameriflux_explorer",path.package("amerifluxr"))
  shiny::runApp(appDir, display.mode = "normal",launch.browser=TRUE)
}