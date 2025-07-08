
# raster_map2.R
library(leaflet)
library(sf)
library(FNN)
library(terra)
library(leaflet.providers)
source("utils/palette_colors.R")

raster_map <- function(df, var_map, basemap = "Stadia", map_opacity = 0.8) {
  req(df)
  req(var_map)

  # Crear sf con coordenadas
  sf_points <- sf::st_as_sf(df, coords = c("Longitude", "Latitude"), crs = 4326)

  # Crear cuadrícula
  lon_range <- range(df$Longitude, na.rm = TRUE)
  lat_range <- range(df$Latitude, na.rm = TRUE)
  n <- 50
  amp <- 0.005
  grid_df <- expand.grid(
    Longitude = seq(lon_range[1] - amp, lon_range[2] + amp, length.out = n * 5),
    Latitude = seq(lat_range[1] - amp, lat_range[2] + amp, length.out = n * 5)
  )
  sf_grid <- sf::st_as_sf(grid_df, coords = c("Longitude", "Latitude"), crs = 4326)

  # Vecinos más cercanos
  coords_data <- sf::st_coordinates(sf_points)
  coords_grid <- sf::st_coordinates(sf_grid)
  nn <- get.knnx(coords_data, coords_grid, k = 1)
  var_values <- df[[var_map]]
  grid_values <- var_values[nn$nn.index]
  sf_grid[[var_map]] <- grid_values

  # Rasterización con terra
  sv <- vect(sf_grid)
  r <- rast(ext(sv), ncol = n, nrow = n, crs = "EPSG:4326")
  r <- rasterize(sv, r, field = var_map)
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
