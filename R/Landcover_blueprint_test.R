#### This is a blueprint / test script for downloading landcover data
# from MODIS using MODIStools package ####
# Nicholas J Clark
# nicholas.j.clark1214@gmail.com

#### If need be, install MODISTools2 ####
#Note, older versions of MODISTools may have problems with broken links!
#Better to remove old versions first and install the most up-to-date version
#remove.packages('MODISTools')
#manually downlaod MODISTools2.tar.gz here (https://modis.ornl.gov/data/modis_webservice.html)
#install.packages("yourfilepath/MODISTools2.tar.gz",repos=NULL,type="source")

#### Import coordinates data (individual sites as rows with 'lat' and 'long' as colnames) ####
test.dat <- data.frame(lat = c(-27.4678, -27.5636, -27.5598),
                       long = c(153.0067, 152.2800, 151.9507))

#### Source functions needed for MODIS downloading and processing from GitHub ####
source("https://raw.githubusercontent.com/nicholasjclark/LandcoverMODIS/master/R/Landcover_functions.R")

#### Download data for the specified years (!! but don't include 2010-2012, see below !!)
download_landcover(years_gather = c(2006:2008), 
                   coordinates = test.dat) #this stores raw data in a new 'LandCover' folder

#### Once all of the necessary files are downloaded, summarise them ####
summarise_landcover() #this writes a .csv summary file in the 'LandCover' folder

####                                                                 ####
#### Some quirky aspects of downloading that need to be acknowledged ####
####                                                                 ####
# 1. Certain years (2010 - 2012) are missing from the Land_Cover_Type_1 band #
#Not sure why this is (maintenance on the satellite??), but they never seem to 
#result in appropriate downloads. For now, these years should be omitted

#Should produce an error message
download_landcover(years_gather = c(2008:2012), 
                   coordinates = test.dat)

# 2. Landcover downloads struggle if we access more than ~100 points at a time
#I've included an error to remind that downloading for multiple subsets is safer
error.dat <- data.frame(lat = rnorm(200, mean = 50),
                        long = rnorm(200, mean = 50))

#Should produce an error message
download_landcover(years_gather = c(2006:2008), 
                   coordinates = error.dat)

#Better to use subsets for sequential downloads i.e.
download_landcover(years_gather = c(2006:2008), 
                   coordinates = test.dat[1:2,])
download_landcover(years_gather = c(2006:2008), 
                   coordinates = test.dat[3:4,])
# etc.....
