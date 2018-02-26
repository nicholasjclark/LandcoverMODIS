
<!-- README.md is generated from README.Rmd. Please edit that file -->
Overview
--------

This repository stores functions written to download MODIS landcover data for coordinates across a range of years. Downloaded raw data can be quickly summarised into a .csv file so that raw ASCII files can be deleted, saving memory (and precious workspace!).

Instructions for use
--------------------

#### 1. If need be, install `MODISTools`

Please note that older versions of `MODISTools` may have problems with broken links! It is therefore better to remove old versions first and install the most up-to-date version, i.e.

``` r
remove.packages('MODISTools') 
```

followed by

``` r
install.packages("https://modis.ornl.gov/files/modissoapservice/MODISTools2.tar.gz",repos=NULL,type="source")
```

or
manually downlaod MODISTools2.tar.gz here (<https://modis.ornl.gov/data/modis_webservice.html>)
followed by

``` r
install.packages("yourfilepath/MODISTools2.tar.gz",repos=NULL,type="source")
```

#### 2. Import coordinates data (individual sites as rows with 'lat' and 'long' as colnames)

``` r
test.dat <- data.frame(lat = c(-27.4678, -27.5636, -27.5598), 
                       long = c(153.0067, 152.2800, 151.9507))
```

#### 3. Source functions needed for MODIS downloading and processing from GitHub

``` r
source("https://raw.githubusercontent.com/nicholasjclark/LandcoverMODIS/master/R/Landcover_functions.R")
```

#### 4. Download data for the specified year (or range of years)

**!! but don't include 2010-2012, see below !!**

This stores the raw downloaded data in a new 'LandCover' folder

``` r
download_landcover(years_gather = c(2006:2008), coordinates = test.dat)
```

#### 4. Once ALL of the necessary files are downloaded, summarise them

**!! Do not summarise before all necessary raw files are downloaded (raw files get deleted) !!**

This writes a .csv summary file in the 'LandCover' folder and deletes the raw files

``` r
summarise_landcover()
```

Some quirky aspects of downloading that need to be acknowledged
---------------------------------------------------------------

#### 1. Certain years (2010 - 2012) are missing from the Land\_Cover\_Type\_1 band

I'm not sure why this is (maintenance on the satellite??), but they never seem to result in appropriate downloads. This should produce an error message:

``` r
download_landcover(years_gather = c(2008:2012), coordinates = test.dat)
```

For now, these years should just be omitted

#### 2. Landcover downloads struggle if we access more than ~100 points at a time

I've included an error to remind that downloading for multiple subsets is safer. This should produce the error message:

``` r
error.dat <- data.frame(lat = rnorm(200, mean = 50),long = rnorm(200, mean = 50))

download_landcover(years_gather = c(2006:2008), coordinates = error.dat)
```

It is recommended to use subsets for sequential downloads i.e.

``` r
download_landcover(years_gather = c(2006:2008), 
                   coordinates = test.dat[1:2,])
download_landcover(years_gather = c(2006:2008), 
                   coordinates = test.dat[3:4,])
```

etc. to get all of the necessary raw data files. Once **ALL** of the subsets are downloaded, **THEN** use the `summarise_landcover()` function

``` r
summarise_landcover()
```

*These directions are also supplied in the `Landcover_blueprint_test.R` file in the `R` folder in case you would like to download the script and/or share it around. Please feel free to let me know if you run into issues!*
