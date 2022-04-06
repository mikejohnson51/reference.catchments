
# reference.catchments

<!-- badges: start -->
<!-- badges: end -->


The goal of reference.catchments is to build simple, valid, catchments for the NHDPlus.

These will serve as the national reference catchments in the USGS geospatial fabric, and will be central to the NOAA Nextgen modelling hydrofabric.


## Dependencies (outside of R and R packages)

- `GDAL` (`ogr2ogr` is used for file conversions)
- `mapshaper` (used for polygon simplification, not enough to use `rmapshaper`)

## Workflow

This project is set up as a series of scripts contained in the workflow directory. They can be run in the following order to tackle the summarized tasks:

### config.R
  - This sets the configuration variables for execution. These include:
  - the epa s3 bucket 
  - the local base directory to build the output folder structure
  - The desired output CRS (set to that of the `FACFDC` DEM files)
  - The Percentage of removable points to retain in simplification." see [here](https://github.com/mbloch/mapshaper/wiki/Command-Reference#-simplify)
  
### 00_vpu_topo.R

 - This prepossessing step identifies the topology list of VPUs and documents which ones touch each other.
 - It creates the `vpu_topology.csv` file in `data/`
 
### 01_nhdplus_data

 - This file scans the EPA s3 bucket for the NHDCatchment zip files. 
 - These are downloaded and unzipped into in the `01_EPA_downloads/` directory created when sourcing config.R
  if they don't yet exist
 - The shapefiles distributed by EPA are then converted to geopackages (GPKG) in the `02_Catchments` directory
  
### 02_clean

 - This file will work over the raw EPA geopackages and run a cleaning algorithm that explodes and re-dissolves fragments in the catchment fabric to ensure simple, valid, polygon geometries are created.
 - The output files are written to `03_cleaned_catchments`
 
### 03_simplify

 - Just as the NHD releases a Catchment and CatchmentSP (simplified) layer, we also release a simplified layers that smooths the "grid" pattern from the edges created during the raster to polygon conversion.
 - We run `mapshaper` over the VPU files to do this as `mapshaper` has a hard 2GB limit on file output size. While the `mapshaper` (Visvalingam) algorithm is topology preserving within the input class, it cannot and does not preserve topology at the VPU boundaries.
 - The output files are written to `04_simplified_catchments`
 
### 04_rectify

 - A separate algorithm is developed to fill the gaps and overlaps created when simplifying VPUS individually.
 - The output files are written to `05_reference_catchments`
 
### 05_merge_conus
 
 - Merge VPUs into a single national reference fabric (stored in `data/`)
 - Run one last cleaning algorithm to ensure complete, seamless coverage

### 06_send_sciencebase

 - If authentication permits, send national geopackage to ScienceBase

