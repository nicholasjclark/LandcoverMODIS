setwd("~/Desktop/testing landcover")
remove.packages('MODISTools')
install.packages("./MODISTools2.tar.gz",repos=NULL,type="source")
library(MODISTools)
library(dplyr)


test.dat <- data.frame(lat = c(-27.4678, -27.5636, -27.5598),
                       long = c(153.0067, 152.2800, 151.9507))


#Create directory to save summary statistics for each site in each year
landcovpath = './LandCover'
dir.create(landcovpath)

#Landcover downloads struggle with long timeseries (>1yr)
#Need to make subsets, taking data for each year from 2001 to 2009
years.gather <-c(2001:2003)
modis.year.subsets = lapply(years.gather,function(x){
  modis.data=data.frame(lat = test.dat$lat,
                        long = test.dat$long,
                        start.date = rep(x,length(test.dat$lat)),
                        end.date = rep(x,length(test.dat$lat)))
  
  #Gather Landcover Data at 10x10km resolution for each point from each year
  MODISSubsets(LoadDat = modis.data, Product = "MCD12Q1", 
               Bands = "Land_Cover_Type_1",
               Size = c(10,10), SaveDir = landcovpath)
  
})

#Record summary statistics for each point in each year ------------------------------------------------------------------
#Calculate summary landcover statistics
source("Prop.LandCover.R")
Prop.LandCover(Dir = landcovpath, Band = "Land_Cover_Type_1")

summarycover = read.csv(paste(landcovpath,
                              list.files(path = landcovpath,
                                                     pattern="MODIS_Land_Cover_Summary"),
                              sep="/"))

#Remove all MODIS files that are no longer needed
file.remove(dir(landcovpath, pattern = "asc|Subset|Land_Cover_Summary", full.names = TRUE))

#Save MODIS summary file
write.csv(summarycover, file = "MODIS.Summary.csv", row.names = T)
