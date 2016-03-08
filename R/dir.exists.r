#' Check the existence of a directory
#' 
#' @param path: path to check for existence
#' @keywords files, management
#' @export
#' @examples
#' # outputting TRUE or FALSE
#' value = dir.exists(path)

dir.exists <- function(d) {
  de <- file.info(d)$isdir
  ifelse(is.na(de), FALSE, de)
}