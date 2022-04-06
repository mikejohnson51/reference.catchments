# Setup
library(dplyr)
library(rmapshaper)
library(nhdplusTools)
library(hyRefactor)
library(sf)
library(units)
library(logger)
library(aws.s3)
library(archive)

sf_use_s2(FALSE)


epa_bucket = 'edap-ow-data-commons'
base_dir   = '/Volumes/Transcend/geometry_paper'

epa_download   = paste0(base_dir, '/01_EPA_downloads/')
catchments_dir = paste0(base_dir, '/02_Catchments/')
cleaned_dir    = paste0(base_dir, '/03_cleaned_catchments/')
simplified_dir = paste0(base_dir, '/04_simplified_catchments/')
reference_dir  = paste0(base_dir, '/05_reference_catchments/')

facfdr_crs = '+proj=aea +lat_0=23 +lon_0=-96 +lat_1=29.5 +lat_2=45.5 +x_0=0 +y_0=0 +datum=NAD83 +units=m +no_defs'


dir.create(epa_download, showWarnings = FALSE)
dir.create(catchments_dir, showWarnings = FALSE)
dir.create(cleaned_dir, showWarnings = FALSE)
dir.create(simplified_dir, showWarnings = FALSE)

