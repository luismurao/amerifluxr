#' Check the existence of a directory
#' 
#' @param path: path to check for existence
#' @keywords file management
#' @export
#' @examples
#' # outputting TRUE or FALSE
#' dir.exists(pat)

dir.exists <- function(d) {
  de <- file.info(d)$isdir
  ifelse(is.na(de), FALSE, de)
}