# AmeriFluxR

The AmeriFluxR is an R toolbox to facilitate easy Ameriflux Level2 data exploration and downloads through a convenient R [shiny](http://shiny.rstudio.com/) based GUI. I'll integrate support for Level3 data in the near future as well as some additional functionality to summarize the data more concisely.

## Installation

You can quick install the package by installing the following dependencies

	install.packages(c("rvest","data.table","RCurl","DT","shiny","shinydashboard","leaflet","plotly","devtools"))

and downloading the package from the github repository

	require(devtools)
	install_github("khufkens/amerifluxr")

## Use

Most people will prefer the GUI to explore data on the fly. To envoke the GUI use the following command:

	ameriflux.explorer()

This will start a shiny application with an R backend in your default browser. Cached data will be downloaded to ~/ameriflux_cache, clear this directory if it gets to big.

The initial metadata which provides information on the location of Ameriflux sites is drawn from the website. This process is sometimes slow making the first loading times longer. Subsequent starts will be faster as this data is stored in the cache directory (ameriflux_metadata.txt). One can query both the data and the site info using independent R functions as well

	ameriflux.info() # returns the site info as ameriflux_metadata.txt
	data = ameriflux.info(path=NULL) # export to data frame

To query data use for example

	download.ameriflux("US-Ha1")

for all raw Harvard Forest data (not gap filled).

# Notes
Use the proper acknowledgements when using the downloaded data. Citing from the AmeriFlux policy page:

" Those who use AmeriFlux Network data for their research are strongly encouraged to acknowledge both the site principal investigators who contributed the data they use, and the support that the AmeriFlux Network data processing and archival receive from the U.S. DOE. Suggested acknowledgment:

We acknowledge the following AmeriFlux sites for their data records: site IDs. In addition, funding for AmeriFlux data resources was provided by the U.S. Department of Energy’s Office of Science."
