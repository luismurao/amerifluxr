# AmeriFluxR

The AmeriFluxR is an R toolbox to facilitate easy Ameriflux data exploration and downloads.

The tool provides access to the Level2 data product, and by default compiles the data into one big data file (stored in ~/ameriflux_cache).

## Installation

You can quick install the package by downloading the devtools package and running the following code:

	require(devtools) # load the devtools library
	install_github("khufkens/amerifluxr") # install the package

## Use
	# start the gui interface by running
	ameriflux.gui()
  
Cached data will be downloaded to ~/ameriflux_cache, clear this directory if it gets to big.

# Notes
Use the proper acknowledgements when using the downloaded data. Citing from the AmeriFlux policy page:

" Those who use AmeriFlux Network data for their research are strongly encouraged to acknowledge both the site principal investigators who contributed the data they use, and the support that the AmeriFlux Network data processing and archival receive from the U.S. DOE. Suggested acknowledgment:

We acknowledge the following AmeriFlux sites for their data records: site IDs. In addition, funding for AmeriFlux data resources was provided by the U.S. Department of Energy’s Office of Science."
