#### Function download_landcover is the workhorse that 
# downloads raw MODIS data from the "Land_Cover_Type_1" band
# for individual coordinates across specified years ####
# Inputs:
#   years_gather: string of numeric years to gather data for each point
#   coordinates: dataframe with colnames 'lat' and 'long'
#
download_landcover = function(years_gather, coordinates){
library(MODISTools)
library(dplyr)

#Certain years are missing from the Land_Cover_Type_1 band (maintenance on the satellite??)
#Need to return an error if these are included in the years_gather argument
if(any(years_gather %in% c(2010, 2011, 2012))){
  stop('Years 2010 - 2012 are missing from the Land_Cover_Type_1 band. Please remove these from years_gather')
}
  
#Gathering data for more than ~100 points at a time can lead to log-off problems
if(nrow(coordinates)>100){
  stop('Extracting for > 100 points at a time often causes log-off problems / loss of data. Better to subset')
}
  
#Create folder in the working directory to save summary statistics for each site in each year
landcovpath <- './LandCover'
dir.create(landcovpath)

modis.year.subsets <- lapply(years_gather, function(x){
  modis.data <- data.frame(lat = coordinates$lat,
                        long = coordinates$long,
                        start.date = rep(x, length(coordinates$lat)),
                        end.date = rep(x, length(coordinates$lat)))
  
#Gather Landcover Data at 10x10km resolution for each point from each year
#and save to the new 'LandCover' folder in the working directory
  MODISSubsets(LoadDat = modis.data, Product = "MCD12Q1", 
               Bands = "Land_Cover_Type_1",
               Size = c(10, 10), SaveDir = landcovpath)
  
})
#End function download_landcover
}


#### Function prop_landcover runs the for-loop to access raw
# MODIS landcover downloads and summarise classes into broader categories ####
prop_landcover <- 
  function(Dir = ".", Band)
  { 
    ########## Define land cover classes for each lc band.
    LC_CLASS <- list(
      Land_Cover_Type_1 = c("Water" = 0, "Evergreen forest" = c(1,2), 
                            "Deciduous forest" = c(3,4), "Mixed forest" = c(5,6),
                            "Shrublands" = c(7,8), "Savannas/Grasslands" = c(9,10),
                            "Permanent wetlands" = 11, "Croplands" = c(12,14), "Urban & built-up" = c(13,16),
                            "Snow & ice" = 15,"Unclassified" = 254, "NoDataFill" = 255),
      
      Land_Cover_Type_2 = c("Water" = 0, "Evergreen Needleleaf forest" = 1, "Evergreen Broadleaf forest" = 2,
                            "Deciduous Needleleaf forest" = 3, "Deciduous Broadleaf forest" = 4, "Mixed forest" = 5,
                            "Closed shrublands" = 6, "Open shrublands" = 7, "Woody savannas" = 8, "Savannas" = 9,
                            "Grasslands" = 10, "Croplands" = 12, "Urban & built-up" = 13, "Barren/Sparsely vegetated" = 16,
                            "Unclassified" = 254, "NoDataFill" = 255),
      
      Land_Cover_Type_3 = c("Water" = 0, "Grasses/Cereal crops" = 1, "Shrubs" = 2, "Broadleaf crops" = 3, "Savanna" = 4,
                            "Evergreen Broadleaf forest" = 5, "Deciduous Broadleaf forest" = 6,
                            "Evergreen Needleleaf forest" = 7, "Deciduous Needleleaf forest" = 8, "Non-vegetated" = 9,
                            "Urban" = 10, "Unclassified" = 254, "NoDataFill" = 255),
      
      Land_Cover_Type_4 = c("Water" = 0, "Evergreen Needleleaf forest" = 1, "Evergreen Broadleaf forest" = 2,
                            "Deciduous Needleleaf forest" = 3, "Deciduous Broadleaf forest" = 4,
                            "Annual Broadleaf vegetation" = 5, "Annual grass vegetation" = 6, "Non-vegetated land" = 7,
                            "Urban" = 8, "Unclassified" = 254, "NoDataFill" = 255),
      
      Land_Cover_Type_5 = c("Water" = 0, "Evergreen Needleleaf forest" = 1, "Evergreen Broadleaf forest" = 2,
                            "Deciduous Needleleaf forest" = 3, "Deciduous Broadleaf forest" = 4, "Shrub" = 5, "Grass" = 6,
                            "Cereal crop" = 7, "Broadleaf crop" = 8, "Urban & built-up" = 9, "Snow & ice" = 10,
                            "Barren/Sparsely vegetated" = 11, "Unclassified" = 254, "NoDataFill" = 255)
    )
    NUM_METADATA_COLS <- 10
    ##########
    
    if(!file.exists(Dir)) stop("Character string input for Dir argument does not resemble an existing file path.")
    
    file.list <- list.files(path = Dir, pattern = "MCD12Q1.*asc$")
    
    if(length(file.list) == 0) stop("Found no MODIS Land Cover ASCII files in Dir.")
    
    if(!any(GetBands("MCD12Q1") == Band)) stop("LandCover is for land cover data. Band specified is not for this product.")
    
    lc.type.set <- LC_CLASS[[which(names(LC_CLASS) == Band)]]
    NoDataFill <- unname(lc.type.set["NoDataFill"])
    ValidRange <- unname(lc.type.set)
    
    lc.summary <- list(NA)
    
    for(i in 1:length(file.list)){
      
      cat("Processing file ", i, " of ", length(file.list), "...\n", sep="")
      
      lc.subset <- read.csv(paste(Dir, "/", file.list[i], sep = ""), header = FALSE, as.is = TRUE)
      names(lc.subset) <- c("nrow", "ncol", "xll", "yll", "pixelsize", "row.id", "land.product.code", 
                            "MODIS.acq.date", "where", "MODIS.proc.date", 1:(ncol(lc.subset) - NUM_METADATA_COLS))
      
      where.long <- regexpr("Lon", lc.subset$where[1])
      where.samp <- regexpr("Samp", lc.subset$where[1])
      where.land <- regexpr("Land", lc.subset$row.id)
      lat <- as.numeric(substr(lc.subset$where[1], 4, where.long - 1))
      long <- as.numeric(substr(lc.subset$where[1], where.long + 3, where.samp - 1))
      band.codes <- substr(lc.subset$row.id, where.land, nchar(lc.subset$row.id))
      
      ifelse(any(grepl(Band, lc.subset$row.id)),
             which.are.band <- which(band.codes == Band),
             stop("Cannot find which rows in LoadDat are band data. Make sure the only ascii files in the directory are 
                  those downloaded from MODISSubsets."))
      
      lc.tiles <- as.matrix(lc.subset[which.are.band,(NUM_METADATA_COLS+1):ncol(lc.subset)], 
                            nrow = length(which.are.band), ncol = length((NUM_METADATA_COLS+1):ncol(lc.subset)))
      
      if(!all(lc.tiles %in% ValidRange)) stop("Some values fall outside the valid range for the data band specified.")
      
      # Screen pixels in lc.tiles: pixels = NoDataFill, or whose corresponding pixel in qc.tiles < QualityThreshold.
      lc.tiles <- matrix(ifelse(lc.tiles != NoDataFill, lc.tiles, NA), 
                         nrow = length(which.are.band))
      
      # Extract year and day from the metadata and make POSIXlt dates (YYYY-MM-DD), ready for time-series analysis.
      year <- as.numeric(substr(lc.subset$MODIS.acq.date, 2, 5))
      day <- as.numeric(substr(lc.subset$MODIS.acq.date, 6, 8))
      lc.subset$date <- strptime(paste(year, "-", day, sep = ""), "%Y-%j")
      
      # Initialise objects to store landscape summaries
      prop.forest <- rep(NA, nrow(lc.tiles))
      prop.shrubland <- rep(NA, nrow(lc.tiles))
      prop.grassland <- rep(NA, nrow(lc.tiles))
      prop.wetland<- rep(NA, nrow(lc.tiles))
      prop.anthro.cropland <- rep(NA, nrow(lc.tiles))
      prop.anthro.urban <- rep(NA, nrow(lc.tiles))
      lc.richness <- rep(NA, nrow(lc.tiles))
      simp.even <- rep(NA, nrow(lc.tiles))
      simp.d <- rep(NA, nrow(lc.tiles))
      no.fill <- rep(NA, nrow(lc.tiles))
      poor.quality <- rep(NA, nrow(lc.tiles))
      
      for(x in 1:nrow(lc.tiles)){
        
        # Calculate mode - most frequent lc class
        lc.freq <- table(lc.tiles[x, ])
        lc.freq <- lc.freq / ncol(lc.tiles)
        lc.freq <- sum(lc.freq^2)
        
        # Calculate Simpson's D diversity index 
        simp.d[x] <- 1 / lc.freq
        
        # Calculate landscape richness and proportion coverages
        lc.richness[x] <- length(table(lc.tiles[x, ]))  
        prop.forest[x] <- length(which(lc.tiles[x,] %in% c(1, 2, 3, 4, 5, 6))) / length(lc.tiles)
        prop.shrubland[x] <- length(which(lc.tiles[x,] %in% c(7, 8))) / length(lc.tiles)
        prop.grassland[x] <- length(which(lc.tiles[x,] %in% c(9, 10))) / length(lc.tiles)
        prop.wetland[x] <- length(which(lc.tiles[x,] %in% c(11))) / length(lc.tiles)
        prop.anthro.cropland[x] <- length(which(lc.tiles[x,] %in% c(12, 14))) / length(lc.tiles)
        prop.anthro.urban[x] <- length(which(lc.tiles[x,] %in% c(13, 16))) / length(lc.tiles)

        # Calculate Simpson's measure of evenness
        simp.even[x] <- simp.d[x] / lc.richness[x]
        
        no.fill[x] <- paste(round((sum(lc.subset[x, (NUM_METADATA_COLS+1):ncol(lc.subset)] == NoDataFill) / 
                                     length(lc.tiles[x, ])) * 100, 2), 
                            "% (", 
                            sum(lc.subset[x, (NUM_METADATA_COLS+1):ncol(lc.subset)] == NoDataFill), 
                            "/", 
                            length(lc.tiles[x, ]), 
                            ")", 
                            sep = "")
        
      } # End of loop that summaries tiles at each time-step, for the ith ASCII file.
      
      # Compile summaries into a table.
      lc.summary[[i]] <- data.frame(lat = lat, long = long, year = year, 
                                    date = lc.subset$date[which(band.codes == Band)],
                                    modis.band = Band, prop.forest = prop.forest,
                                    prop.shrubland = prop.shrubland, prop.grassland = prop.grassland,
                                    prop.wetland = prop.wetland, prop.anthro.urban = prop.anthro.urban,
                                    prop.anthro.cropland = prop.anthro.cropland, richness = lc.richness,
                                    simpsons.d = simp.d, simpsons.evenness = simp.even, no.data.fill = no.fill)
      
    } # End of loop that reiterates for each ascii file.
    
    # Write output summary file by appending summary data from all files, producing one file of summary output.
    lc.summary <- do.call("rbind", lc.summary)
    write.table(lc.summary, file = paste(Dir, "/", "MODIS_Land_Cover_Summary ", Sys.Date(), ".csv", sep = ""),
                sep = ",", row.names = FALSE)
    
    cat("Done! Check the 'MODIS Land Cover Summary' output file.\n")
    #End function prop_landcover
  }

#### Function summarise_landcover uses function prop_landcover to 
# summarise raw MODIS downloads to return proportions of landcover 
# for each site in each year ####
summarise_landcover = function(){
  landcovpath <- './LandCover'
prop_landcover(Dir = landcovpath, Band = "Land_Cover_Type_1")

summarycover <- read.csv(paste(landcovpath,
                              list.files(path = landcovpath,
                                         pattern="MODIS_Land_Cover_Summary"),
                              sep="/"))

#Remove all MODIS files that are no longer needed
file.remove(dir(landcovpath, 
                pattern = "asc|Subset|Land_Cover_Summary", 
                full.names = TRUE))

#Save MODIS summary file
write.csv(summarycover, file = "./LandCover/MODIS_Landcover_summary.csv", row.names = T)
}