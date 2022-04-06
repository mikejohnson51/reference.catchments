source('workflow/config.R')

gpkgs = list.files(reference_dir, full.names = TRUE, pattern = ".gpkg$")

vpu = gsub(".gpkg", "", gsub(paste0(reference_dir, "/NHDPlus"), "", gpkgs))

rpuid = get_vaa('rpuid')

tmp = list()

for(i in 1:length(gpkgs)){
  tmp[[i]] = read_sf(gpkgs[i]) |>
  mutate(vpuid = vpu[i]) |>
  left_join(rpuid, by = c("featureid" = "comid")) |>
  rename_geometry("geometry") |>
  select(-gridcode, -sourcefc) |>
  st_transform(facfdr_crs)

  message(vpu[i])
}


all = bind_rows(tmp)

unlink("data/reference_catchments.rds")
saveRDS(all,  "data/reference_catchments.rds")

unlink("data/reference_catchments.gpkg")
write_sf(all, "data/reference_catchments.gpkg")

