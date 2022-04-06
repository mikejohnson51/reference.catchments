source("workflow/config.R")

gpkgs <- list.files(reference_dir, full.names = TRUE, pattern = ".gpkg$")

vpu <- gsub(".gpkg", "", gsub(paste0(reference_dir, "/NHDPlus"), "", gpkgs))

rpuid <- get_vaa("rpuid")

output <- list()

for (i in 1:length(gpkgs)) {

  tst <- read_sf(gpkgs[i]) |>
    st_cast("POLYGON") %>%
    mutate(areasqkm = add_areasqkm(.)) |>
    mutate(tmpID = 1:n()) |>
    rename_geometry("geometry")

  dups <- tst$featureid[which(duplicated(tst$featureid))]

  if(length(dups) != 0){

      bad <- filter(tst, featureid %in% dups) |>
        group_by(featureid) |>
        slice_min(areasqkm) |>
        ungroup()

      good <- filter(tst, !tmpID %in% bad$tmpID)

      out <- tryCatch(
        {
          suppressWarnings({
            st_intersection(bad, select(good, tmpID)) %>%
              st_collection_extract("POLYGON") |>
              filter(tmpID != tmpID.1)
          })
        },
        error = function(e) {
          NULL
        }
      )


      ints <- out %>%
        mutate(l = st_area(.)) %>%
        group_by(.data$tmpID) %>%
        slice_max(.data$l, with_ties = FALSE) %>%
        ungroup() %>%
        select(.data$tmpID.1, .data$tmpID, .data$l) %>%
        st_drop_geometry()

      tj <- right_join(bad,
        ints,
        by = "tmpID"
      ) %>%
        select(badID = tmpID, tmpID = tmpID.1, featureid)

      tmp <- bind_rows(tj, filter(good, tmpID %in% tj$tmpID)) |>
        hyRefactor::union_polygons_geos("tmpID") |>
        select(tmpID)

      tmp2 <- filter(good, tmpID %in% tmp$tmpID) |>
        st_drop_geometry() |>
        right_join(tmp)

      tst = bind_rows(
        filter(good, !tmpID %in% tmp2$tmpID),
        tmp2
      )
}


  output[[i]] <- tst |>
    mutate(vpuid = vpu[i]) |>
    left_join(rpuid, by = c("featureid" = "comid")) |>
    rename_geometry("geometry") |>
    select(-gridcode, -sourcefc, -tmpID) |>
    st_transform(facfdr_crs)

  message(vpu[i])
}


all <- bind_rows(output) |>
  st_make_valid()

rm(output)

unlink("data/reference_catchments.rds")
saveRDS(all, "data/reference_catchments.rds")

unlink("data/reference_catchments.gpkg")
write_sf(all, "data/reference_catchments.gpkg")
