
# raster_map2.R
library(leaflet)
library(sf)
library(FNN)
library(terra)
library(leaflet.providers)
source("utils/palette_colors.R")

raster_map <- function(df, var_map, basemap = "Stadia", map_opacity = 0.8, n = 50, buffer_dist = 200) {
  req(df)
  req(var_map)

  # Crear sf con coordenadas
  sf_points <- sf::st_as_sf(df, coords = c("Longitude", "Latitude"), crs = 4326)

  # Crear buffer alrededor de todos los puntos
  sf_points_proj <- sf::st_transform(sf_points, 3857)  # Proyección métrica para usar metros
  buffer_union <- sf::st_union(sf::st_buffer(sf_points_proj, dist = buffer_dist))
  buffer_union <- sf::st_transform(buffer_union, 4326)  # Volver a latlon para leaflet/terra

  # Crear grid SOLO dentro del buffer
  bbox <- sf::st_bbox(buffer_union)
  grid_df <- expand.grid(
    Longitude = seq(bbox$xmin, bbox$xmax, length.out = n * 5),
    Latitude = seq(bbox$ymin, bbox$ymax, length.out = n * 5)
  )
  sf_grid <- sf::st_as_sf(grid_df, coords = c("Longitude", "Latitude"), crs = 4326)
  sf_grid <- sf_grid[sf::st_within(sf_grid, buffer_union, sparse = FALSE), ]

  # Vecinos más cercanos
  coords_data <- sf::st_coordinates(sf_points)
  coords_grid <- sf::st_coordinates(sf_grid)
  nn <- FNN::get.knnx(coords_data, coords_grid, k = 1)
  var_values <- df[[var_map]]
  grid_values <- var_values[nn$nn.index]
  sf_grid[[var_map]] <- grid_values

  # Rasterización con terra
  sv <- terra::vect(sf_grid)
  r <- terra::rast(ext(sv), ncol = n, nrow = n, crs = "EPSG:4326")
  r <- terra::rasterize(sv, r, field = var_map)

  cats <- terra::cats(r)[[1]]  # Tiene columnas: value (códigos), category (etiquetas)

  # Extraer códigos y etiquetas en orden correcto
  codes <- cats$value
  labels <- cats$category

  map_provider <- switch(basemap,
                         "OSM" = providers$OpenStreetMap.Mapnik,
                         "Satélite" = providers$Esri.WorldImagery,
                         "Esri" = providers$Esri.WorldGrayCanvas,
                         "Stadia" = providers$Stadia.AlidadeSmooth)

  # Paleta: según tipo de variable


  draw_leaflet_map(r, var_map, var_values, df, cats$value, map_provider, map_opacity)

}
