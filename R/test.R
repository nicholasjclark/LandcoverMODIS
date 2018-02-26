#### This is a blueprint / test script for downloading landcover data
# from MODIS using the MODIStools package (https://modis.ornl.gov/data/modis_webservice.html) ####

#### If need be, install MODISTools2 ####
#Note, older versions of MODISTools may have problems with broken links!
#remove.packages('MODISTools')
#install.packages("./MODISTools2.tar.gz",repos=NULL,type="source")

#### Import coordinates data (individual sites as rows with 'lat' and 'long' as colnames) ####
test.dat <- data.frame(lat = c(-27.4678, -27.5636, -27.5598),
                       long = c(153.0067, 152.2800, 151.9507))



source("~/Google Drive/Academic Work Folder/LandcoverMODIS/R/Landcover_functions.R")
download_landcover(years_gather = c(2008), 
                   coordinates = error.dat)
summarise_landcover()

#### Some quirky aspects of downloading that need to be acknowledged ####
# 1. Landcover downloads struggle if we access more than ~100 points at a time
#I've included an error to remind that downloading for multiple subsets is safer
error.dat <- data.frame(lat = rnorm(200, mean = 50),
                        long = rnorm(200, mean = 50))
