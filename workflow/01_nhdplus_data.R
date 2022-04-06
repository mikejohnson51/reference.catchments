source("workflow/config.R")

df = get_bucket_df(epa_bucket, max = Inf)
dir.create(epa_download, showWarnings = FALSE)

v = grep("_NHDPlusCatchment_", df$Key, value =TRUE)

list.files(epa_download, recursive  = TRUE, pattern = ".shp$")

####

all = data.frame(
  key = v,
  VPU = sapply(strsplit(v, "_"), `[`, 3),
  region = sapply(strsplit(v, "_"), `[`, 2),
  link = paste0('https://', epa_bucket, '.s3.amazonaws.com/', v)) |>
mutate(outfile = paste0(epa_download, "/NHDPlus", VPU, ".7z"),
              shp = paste0("NHDPlus", region, "/NHDPlus", VPU, '/NHDPlusCatchment/Catchment.shp'))

df = filter(all, !all$shp %in% list.files(epa_download, recursive  = TRUE, pattern = ".shp$"))

####

for(i in 1:nrow(df)){
  save_object(object = df$key[i], bucket = epa_bucket,file = df$outfile[i])
  archive_extract(df$outfile[i], dir = epa_download)
  unlink(df$outfile[i])
}

####

all$gpkg = paste0(catchments_dir, "/NHDPlus", all$VPU, ".gpkg")

df2 = df = filter(all, !all$gpkg %in% list.files(catchments_dir, full.names = TRUE))

if(nrow(df2) > 0){
  calls = paste('ogr2ogr -f GPKG',
        df2$gpkg,
        df2$shp)

  for(i in 1:length(calls)){
    system(calls[i])
    message(i)
  }
}

