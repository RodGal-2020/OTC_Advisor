

# raster_map.R
library(leaflet)
library(sf)
library(FNN)
library(terra)
library(leaflet.providers)

raster_map <- function(df, var_map, basemap = "Stadia", map_opacity = 0.8) {
  req(df)
  req(var_map)

  # Crear sf con coordenadas
  sf_points <- sf::st_as_sf(df, coords = c("Longitude", "Latitude"), crs = 4326)

  # Crear cuadrícula
  lon_range <- range(df$Longitude, na.rm = TRUE)
  lat_range <- range(df$Latitude, na.rm = TRUE)
  n <- 50
  amp <- 0.00
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

  map_provider <- switch(basemap,
                         "OSM" = providers$OpenStreetMap.Mapnik,
                         "Satélite" = providers$Esri.WorldImagery,
                         "Esri" = providers$Esri.WorldGrayCanvas,
                         "Stadia" = providers$Stadia.AlidadeSmooth)

  # Paleta: según tipo de variable
  if (is.numeric(var_values)) {
    valores <- values(r)
    pal <- colorNumeric("viridis", domain = range(valores, na.rm = TRUE), na.color = "#000000")
    leaflet() %>%
      addProviderTiles(map_provider) %>%
      addRasterImage(r, colors = pal, opacity = map_opacity) %>%
      addLegend(pal = pal, values = valores, title = var_map, position = "bottomright") %>%
      setView(lng = mean(df$Longitude, na.rm = TRUE), lat = mean(df$Latitude, na.rm = TRUE), zoom = 14)
  } else {
    sf_grid[[var_map]] <- factor(sf_grid[[var_map]])
    sv <- terra::vect(sf_grid)
    r <- terra::rasterize(sv, r, field = var_map)
    cats <- terra::cats(r)[[1]]  # Data frame con columnas: ID y label o category
    codes <- cats$value             # por ejemplo: 0, 1, 2...
    labels <- cats$category          # por ejemplo: "Cold", "Hot", etc.
    pal <- colorFactor(viridis::viridis(length(codes)), domain = codes)
    leaflet() %>%
      addProviderTiles(map_provider) %>%
      addRasterImage(r, colors = pal, opacity = map_opacity, project = FALSE) %>%
      addLegend(colors = pal(codes), labels = labels, title = var_map, position = "bottomright") %>%
      setView(lng = mean(df$Longitude, na.rm = TRUE), lat = mean(df$Latitude, na.rm = TRUE), zoom = 14)
  }
}




