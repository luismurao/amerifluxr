# Start the AmerifluxR shiny interface
#' @keywords GUI
#' @export
#' @examples
#' # outputting TRUE or FALSE
#' amerifluxr()

amerifluxr <- function(){
  appDir = sprintf("%s/R/inst/shiny/ameriflux_explorer",path.package("amerifluxr"))
  #appDir='/data/Dropbox/Research_Projects/code_repository/bitbucket/amerifluxr/R/inst/shiny/ameriflux_explorer'
  shiny::runApp(appDir, display.mode = "normal",launch.browser=TRUE)
}