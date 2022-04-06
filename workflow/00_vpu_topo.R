library(nhdR)
library(sf)
library(dplyr)

vpus = vpu_shp[vpu_shp$UnitType == "VPU", ]
dt = st_make_valid(vpus)

x = as.data.frame(which(st_intersects(dt, sparse = FALSE), arr.ind = T))

vars = lapply(1:nrow(x), function(y){
  A <- as.numeric(x[y, ])
  A[order(A)]
})

do.call('rbind', vars)[!duplicated(vars),] |>
  data.frame() |>
  setNames(c("VPU1", "VPU2")) |>
  filter(VPU1 != VPU2) |>
  mutate(VPU1 = dt$UnitID[VPU1],
         VPU2 = dt$UnitID[VPU2]) |>
  write.csv("data/vpu_topology.csv", row.names = FALSE)
