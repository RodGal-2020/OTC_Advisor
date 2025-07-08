


library(scales)
library(viridis)

get_var_type <- function(var_name) {
  if (var_name %in% c("Air_temperature", "Globe_temperature", "UTCI")) {
    return("temperature")
  } else if (var_name %in% c("Radiant_temperature")) {
    return("radiation")
  } else if (var_name %in% c("Relative_humidity")) {
    return("humidity")
  } else if (var_name %in% c("Wind_speed")) {
    return("wind")
  } else if (var_name %in% c("ClassificationUTCI", "Subjective_thermal_sensation", "OTC_Prediction")) {
    return("categorical")
  } else if (var_name %in% c("OTC_Probability")) {
    return("otc_probs")
  } else if (var_name %in% c("Classification.UTCI")) {
    return("utci")
  } else {
    return("numeric")  # por defecto
  }
}



get_color_palette <- function(var_name, var_values, codigo) {
  type <- get_var_type(var_name)

  if (type == "temperature") {
    temp_palette <- colorRampPalette(c(
      "#41b6c4",  # celeste
      "#ffffbf",  # blanco-amarillo (neutro)
      "#fdae61",  # naranja
      "#d7191c",  # rojo intenso
      "#67001f",  # rojo muy oscuro
      "#5D0000"   # rojo muy muy oscuro
    ))

    pal <- colorNumeric(
      palette = temp_palette(100),  # 100 colores interpolados
      domain = c(10, 50),
      na.color = "#000000"
    )

  } else if (type == "radiation") {
    temp_palette <- colorRampPalette(c("#313695","#4575B4","#74ADD1","#ABD9E9","#E0F3F8","#FFFFBF","#FEE090","#FDAE61","#F46D43", "#D73027", "#A50026"))

    pal <- colorNumeric(
      palette = temp_palette(100),  # 100 colores interpolados
      domain = c(0, 80),
      na.color = "#000000"
    )

  } else if (type == "humidity") {
    pal <- colorNumeric(
      palette = "Blues",
      domain = range(var_values, na.rm = TRUE),
      na.color = "#000000"
    )

  } else if (type == "wind") {
    pal <- colorNumeric(
      palette = "Greens",
      domain = range(var_values, na.rm = TRUE),
      na.color = "#000000"
    )

  } else if (type == "categorical") {
    levels <- c("Very cold", "Cold", "Neither cool nor warm", "Warm", "Very hot")  # ajustable según variable
    cols <- c("#2c7bb6", "#abd9e9", "#ffffbf", "#fdae61", "#d7191c")

    pal <- colorFactor(
      palette = c("#2c7bb6", "#abd9e9", "#ffffbf", "#fdae61", "#d7191c"),
      domain = codigo,
      na.color = "#000000"
    )

  } else if (type == "otc_probs") {
    pal <- colorNumeric(
      palette = "Greens",
      domain = c(0,1),
      na.color = "#000000"
    )

  } else if (type == "utci") {
    # levels <- c("Very cold", "Cold", "Neither cool nor warm", "Warm", "Very hot")  # ajustable según variable
    # cols <- c("#313695","#4575B4","#74ADD1","#ABD9E9","#E0F3F8","#FFFFBF","#FEE090","#FDAE61","#F46D43", "#D73027", "#A50026")

    pal <- colorFactor(
      palette = c("#313695","#4575B4","#74ADD1","#ABD9E9","#E0F3F8","#FFFFBF","#FEE090","#FDAE61","#F46D43", "#D73027", "#A50026"),
      domain = codigo,
      na.color = "#000000"
    )

  } else {
    # numérico genérico
    pal <- colorNumeric(
      palette = viridis(7, alpha = alpha),
      domain = range(var_values, na.rm = TRUE),
      na.color = "#000000"
    )
  }

  return(pal)
}



draw_leaflet_map <- function(r, var_map, var_values, df, codigo, map_provider, map_opacity = 0.8) {
  pal <- get_color_palette(var_map, var_values, codigo)
  leaflet_base <- leaflet() %>%
    addProviderTiles(map_provider) %>%
    addRasterImage(r, colors = pal, opacity = map_opacity, project = FALSE)

  # Leyenda: adaptativa según tipo de paleta
  if (var_map == "Classification.UTCI") {
    cats <- terra::cats(r)[[1]]  # Tiene columnas: value (códigos), category (etiquetas)

    codes <- cats$value
    domain_vals <- cats$category

    colores <- c("#313695","#4575B4","#74ADD1","#ABD9E9","#E0F3F8","#FFFFBF","#FEE090","#FDAE61","#F46D43", "#D73027", "#A50026")

    leaflet_base <- leaflet_base %>%
      addLegend(
        colors = colores,
        labels = domain_vals,
        title = var_map,
        position = "bottomright"
      )

  } else if (attr(pal, "colorType") == "factor") {
    cats <- terra::cats(r)[[1]]  # Tiene columnas: value (códigos), category (etiquetas)

    codes <- cats$value
    domain_vals <- cats$category

    colores <- c("#2c7bb6", "#abd9e9", "#ffffbf", "#fdae61", "#d7191c")

    leaflet_base <- leaflet_base %>%
      addLegend(
        colors = colores,
        labels = domain_vals,
        title = var_map,
        position = "bottomright"
      )

  } else {
    # Si es colorNumeric u otro tipo numérico
    leaflet_base <- leaflet_base %>%
      addLegend(
        pal = pal,
        values = var_values,
        title = var_map,
        position = "bottomright"
      )
  }

  # Centrar el mapa
  leaflet_base %>%
    setView(
      lng = mean(df$Longitude, na.rm = TRUE),
      lat = mean(df$Latitude, na.rm = TRUE),
      zoom = 14
    )
}
