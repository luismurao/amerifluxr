# AmeriFlux Download Tool

The AmeriFlux Download Tool is a bash script for Linux/Mac OSX or system independent R script to facilitate easy downloading of publicly available data on carbon, water and energy exchange between the biosphere and the atmosphere contributed to the [AmeriFlux](http://ameriflux.lbl.gov/) network.

The tool provides access to the Level2 data product, and by default compiles the data into one big data file. For hourly data the files are sufficiently small to be imported on most computers. This option can be disabled if your system is slow or you do not have use for it in your workflow.

## Installation

clone the project to your home computer using the following command (with git installed)

	git clone https://khufkens@bitbucket.org/khufkens/ameriflux-download-tool.git

alternatively, download the project using [this link](https://bitbucket.org/khufkens/ameriflux-download-tool/get/master.zip).

Unzip the downloaded files or use the files cloned by git as is. The shell script should be made executable using the following command:

	chmod +x download.AMF.sh

The R script should be loaded into your workspace using the following command:

	source("download.AMF.r")

(when the current working directory is set to the location of download.AMF.r)

## Use

### Bash shell script
Downloading files is as simple as running this command

	sh download.AMF.sh -s site_ID -d /foo/bar -g TRUE -t hourly -m TRUE
or

	./download.AMF.sh -s site_ID -d /foo/bar -g TRUE -t hourly -m TRUE

with:

Parameter     | Description                    	
------------- | ------------------------------ 	
-s		 | The AmeriFlux site ID (example: US-Bar, for the Bartlett flux site in NH)
-d 		 | The output directory where to put the data (default is the present working directory)
-g      	 | Do you want raw non gap filled data (TRUE/FALSE, default = TRUE)
-t      	 | If there are multiple products which timestep to use (hourly / half_hourly; default=hourly)
-m            | Should the yearly values be merged (TRUE/FALSE, default = TRUE)

[only the -s parameter is required!]

An example:

	./download.AMF.sh -s US-Bar

will download all available Level2 data for the Bartlett flux site in the White Mountains of New Hampshire. The downloaded files will be merged in one big file.

While,

	./download.AMF.sh -s US-Bar -m FALSE

will not merge the downloaded files.

### R

The R code is a bit more restrictive as it does not allow you NOT to merge the data into one big file and only takes one argument (gaps: TRUE / FALSE), it will also only consider hourly data instead of providing the option to process half hourly data. However, unlike the bash script the code will work on any OS running R. 

Downloading all Harvard forest data is done as such:

	download.AMF(site="US-Ha1", gaps=FALSE)

will download all available Level2 data for the Harvard forest. The downloaded files will be merged in one big file and written to the current working directory.

## Notes

Mac OSX does not seem to support wget by default, for whatever reason that might be. You will need to compile wget from source as described here to make use of this tool. Instructions can be found [here](http://osxdaily.com/2012/05/22/install-wget-mac-os-x/). I might rewrite the tool using curl commands only on a later date or update the features of the R script.

Furthermore, use the proper acknowledgements when using the downloaded data. Citing from the AmeriFlux policy page:

" Those who use AmeriFlux Network data for their research are strongly encouraged to acknowledge both the site principal investigators who contributed the data they use, and the support that the AmeriFlux Network data processing and archival receive from the U.S. DOE. Suggested acknowledgment:

We acknowledge the following AmeriFlux sites for their data records: site IDs. In addition, funding for AmeriFlux data resources was provided by the U.S. Department of Energy’s Office of Science."