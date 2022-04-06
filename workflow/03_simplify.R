all       = list.files(cleaned_dir, full.names = TRUE, pattern = ".geojson$")

out  = paste0(simplified_dir, "/", gsub(".geojson", "", basename(all)), "_t", num, ".geojson")
out2 = gsub('geojson', "gpkg", out)

for(i in 1:length(out2)){
  if(!file.exists(out2[i])){
    system(paste0('node  --max-old-space-size=16000 `which mapshaper` ', all[i], ' -simplify ',num, '% keep-shapes -o ', out[i]))
    system(paste('ogr2ogr', out2[i], out[i], "-nln catchments"))
    unlink(out[i])
  }

  log_info("Simplified: ", i ,  " of ", length(out2))
}

