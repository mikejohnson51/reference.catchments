
topos = read.csv("data/vpu_topology.csv")


files       = list.files(simplified_dir, full.names = TRUE, pattern = ".gpkg$")

find_file_path = function(VPU, files, new_dir){
  tmp01 = grep(VPU, files, value = TRUE)
  tmp02 = paste0(new_dir, "/", gsub("\\_.*", "", basename(tmp01)), ".gpkg")

  if(!file.exists(tmp02)){ file.copy(tmp01, tmp02) }

  tmp02
}

for(i in 1:nrow(topos)){

  VPU1 = topos$VPU1[i]
  VPU2 = topos$VPU2[i]

  v_path_1 = find_file_path(VPU1, files, new_dir)
  v_path_2 = find_file_path(VPU2, files, new_dir)

  log_info('\tRead in touching pairs')
    v1 = read_sf(v_path_1) |>
      st_transform(5070) |>
      st_make_valid() |>
      rename_geometry('geometry')

    v2 = read_sf(v_path_2) |>
      st_transform(5070) |>
      st_make_valid() |>
      rename_geometry('geometry')

  log_info('\tIsolate "edge" catchments')
    old_1 = st_filter(v1, v2)
    old_2 = st_filter(v2, v1)

  log_info('\tErase fragments of OVERLAP')
    new_1 = st_difference(old_1, st_union(st_combine(old_2)))
    new_2 = st_difference(old_2, st_union(st_combine(old_1)))

    u1 = sf_remove_holes(st_union(new_1))
    u2 = sf_remove_holes(st_union(new_2))

   log_info('\tBuild Fragments')

    base_cats = bind_rows(new_1, new_2)
    base_union = sf_remove_holes(st_union(c(u1,u2)))

    frags = st_difference(base_union, st_union(st_combine(base_cats))) |>
      st_cast("MULTIPOLYGON") |>
      st_cast("POLYGON") |>
      st_as_sf() |>
      mutate(id = 1:n()) %>%
      rename_geometry('geometry') |>
      st_buffer(.0001)

    out = tryCatch({
      suppressWarnings({
        st_intersection(frags, base_cats) %>%
          st_collection_extract("POLYGON")
      })
    }, error = function(e) { NULL })


  ints = out %>%
    mutate(l = st_area(.)) %>%
    group_by(.data$id) %>%
    slice_max(.data$l, with_ties = FALSE) %>%
    ungroup() %>%
    select(.data$featureid, .data$id, .data$l) %>%
    st_drop_geometry()

  tj = right_join(frags,
                  ints,
                  by = "id") %>%
    bind_rows(base_cats) %>%
    dplyr::select(-.data$id) %>%
    group_by(.data$featureid) %>%
    mutate(n = n()) %>%
    ungroup()

  in_cat = suppressWarnings({
    hyRefactor::union_polygons_geos(filter(tj, .data$n > 1) , 'featureid') %>%
      bind_rows(dplyr::select(filter(tj, .data$n == 1), .data$featureid)) %>%
      mutate(tmpID = 1:n()) |>
      st_make_valid()
  })

  log_info('\tReassemble VPUS')

    inds = in_cat$featureid[in_cat$featureid %in% v1$featureid]

    to_keep_1 = bind_rows( filter(v1, !featureid %in% inds),
                           filter(in_cat, featureid %in% inds)) |>
      select(names(v1)) %>%
      mutate(areasqkm = hyRefactor::add_areasqkm(.))

    inds2 = in_cat$featureid[in_cat$featureid %in% v2$featureid]

    to_keep_2 = bind_rows( filter(v2, !featureid %in% inds2),
                           filter(in_cat, featureid %in% inds2)) |>
      select(names(v1)) %>%
      mutate(areasqkm = hyRefactor::add_areasqkm(.))

    log_info('\tWrite VPUS')
    write_sf(to_keep_1, v_path_1, "catchments", overwrite = TRUE)
    write_sf(to_keep_2, v_path_2, "catchments", overwrite = TRUE)

    log_info('Finished: ', i , " of ", nrow(topos))

}







