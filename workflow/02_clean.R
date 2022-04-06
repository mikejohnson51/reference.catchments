source('workflow/config.R')

files       = list.files(catchments_dir, full.names = TRUE, pattern = ".gpkg$")

out_gpkg    = paste0(cleaned_dir, basename(files))

out_geojson = gsub('gpkg', 'geojson', out_gpkg)


for(i in 1:length(files)){

  if(!file.exists(out_geojson[i])){
    catchments  = read_sf(files[i])
    names(catchments) = tolower(names(catchments))

    ll = clean_geometry(
      catchments,
      sys = TRUE,
      'featureid',
      keep = NULL)

    lt          =  st_make_valid(ll)
    lt$areasqkm = drop_units(set_units(st_area(lt), "km2"))
    lt          = st_transform(lt, 4326)

    write_sf(lt, out_gpkg[i])
    write_sf(lt, out_geojson[i])

    rm(ll); rm(catchments); rm(lt); gc()
  }
  log_info("Cleaned VPU: ",i,  " of ", length(files))
}

