


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
  } else if (var_name %in% c("ClassificationUTCI", "df[[var_map]]", "OTC_Prediction")) {
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
      na.color = "transparent"
    )

  } else if (type == "radiation") {
    temp_palette <- colorRampPalette(c("#313695","#4575B4","#74ADD1","#ABD9E9","#E0F3F8","#FFFFBF","#FEE090","#FDAE61","#F46D43", "#D73027", "#A50026"))

    pal <- colorNumeric(
      palette = temp_palette(100),  # 100 colores interpolados
      domain = c(0, 80),
      na.color = "transparent"
    )

  } else if (type == "humidity") {
    pal <- colorNumeric(
      palette = "Blues",
      domain = range(var_values, na.rm = TRUE),
      na.color = "transparent"
    )

  } else if (type == "wind") {
    pal <- colorNumeric(
      palette = "Greens",
      domain = range(var_values, na.rm = TRUE),
      na.color = "transparent"
    )

  } else if (type == "categorical") {
    levels <- c("Very cold", "Cold", "Neither cool nor warm", "Warm", "Very hot")  # ajustable según variable
    cols <- c("#2c7bb6", "#abd9e9", "#ffffbf", "#fdae61", "#d7191c")

    pal <- colorFactor(
      palette = c("#2c7bb6", "#abd9e9", "#ffffbf", "#fdae61", "#d7191c"),
      domain = codigo,
      na.color = "transparent"
    )

  } else if (type == "otc_probs") {
    pal <- colorNumeric(
      palette = "OrRd",
      domain = c(0,100),
      na.color = "transparent"
    )

  } else if (type == "utci") {
    # levels <- c("Very cold", "Cold", "Neither cool nor warm", "Warm", "Very hot")  # ajustable según variable
    # cols <- c("#313695","#4575B4","#74ADD1","#ABD9E9","#E0F3F8","#FFFFBF","#FEE090","#FDAE61","#F46D43", "#D73027", "#A50026")

    pal <- colorFactor(
      palette = c("#313695","#4575B4","#74ADD1","#ABD9E9","#E0F3F8","#FFFFBF","#FEE090","#FDAE61","#F46D43", "#D73027", "#A50026"),
      domain = codigo,
      na.color = "transparent"
    )

  } else {
    # numérico genérico
    pal <- colorNumeric(
      palette = viridis(7, alpha = alpha),
      domain = range(var_values, na.rm = TRUE),
      na.color = "transparent"
    )
  }

  return(pal)
}

var_labels <- list(
  Air_temperature         = "Air temperature (°C)",
  Globe_temperature       = "Globe temperature (°C)",
  Radiant_temperature     = "Radiant temperature (°C)",
  Relative_humidity       = "Relative humidity (%)",
  Wind_speed              = "Wind speed (m/s)",
  UTCI                    = "UTCI (°C)",
  Classification.UTCI     = "Classification UTCI",
  OTC_Probability         = "OTC Probability (%)",
  OTC_Prediction          = "OTC Prediction"
)



get_var_label <- function(var_map) {
  var_labels[[var_map]] %||% var_map  # si no está en la lista, devuelve el nombre original
}


draw_leaflet_map <- function(r, var_map, var_values, df, codigo, map_provider, map_opacity = 0.8) {

  pal <- get_color_palette(var_map, var_values, codigo)

  # Leyenda: adaptativa según tipo de paleta
  if (var_map == "Classification.UTCI") {
    cats <- terra::cats(r)[[1]]  # Tiene columnas: value (códigos), category (etiquetas)

    codes <- cats$value
    domain_vals <- cats$category
    equivalencias <- data.frame(
      code = codes,
      label = domain_vals,
      stringsAsFactors = FALSE
    )

    colores <- c("#313695","#4575B4","#74ADD1","#ABD9E9","#E0F3F8","#FFFFBF","#FEE090","#FDAE61","#F46D43", "#D73027", "#A50026")

    df$cod <- equivalencias$code[match(df[[var_map]], equivalencias$label)]

    df$color_points <- pal(df$cod)

    leaflet_base <- leaflet() %>%
      addProviderTiles(map_provider) %>%
      addRasterImage(r, colors = pal, opacity = map_opacity, project = FALSE) %>%
      addLegend(
        colors = colores,
        labels = domain_vals,
        title = get_var_label(var_map),
        position = "bottomright"
      )

  } else if (attr(pal, "colorType") == "factor") {
    cats <- terra::cats(r)[[1]]  # Tiene columnas: value (códigos), category (etiquetas)

    codes <- cats$value
    domain_vals <- cats$category
    equivalencias <- data.frame(
      code = codes,
      label = domain_vals,
      stringsAsFactors = FALSE
    )

    colores <- c("#2c7bb6", "#abd9e9", "#ffffbf", "#fdae61", "#d7191c")

    df$cod <- equivalencias$code[match(df[[var_map]], equivalencias$label)]

    df$color_points <- pal(df$cod)

    leaflet_base <- leaflet() %>%
      addProviderTiles(map_provider) %>%
      addRasterImage(r, colors = pal, opacity = map_opacity, project = FALSE) %>%
      addLegend(
        colors = colores,
        labels = domain_vals,
        title = get_var_label(var_map),
        position = "bottomright"
      )

  } else {
    # Si es colorNumeric u otro tipo numérico

    df$color_points <- pal(df[[var_map]])

    leaflet_base <- leaflet() %>%
      addProviderTiles(map_provider) %>%
      addRasterImage(r, colors = pal, opacity = map_opacity, project = FALSE) %>%
      addLegend(
        pal = pal,
        values = var_values,
        title = get_var_label(var_map),
        position = "bottomright"
      )
  }

  # Centrar el mapa
  leaflet_base %>%
    addCircleMarkers(
      data = df,
      lng = ~Longitude,
      lat = ~Latitude,
      fillColor = ~color_points,   # Color de relleno (interior del punto)
      radius = 5,
      fillOpacity = 0.8,
      stroke = TRUE,               # Activa el borde
      color = "black",             # Color del borde
      weight = 1,                  # Grosor del borde
      opacity = 1,                 # Opacidad del borde
      label = ~as.character(df[[var_map]]),
      labelOptions = labelOptions(direction = "auto")
    ) %>%
    # addCircleMarkers(
    #   data = df,
    #   lng = ~Longitude,
    #   lat = ~Latitude,
    #   color = ~color_points,
    #   radius = 5,
    #   fillOpacity = 0.8,
    #   stroke = FALSE,
    #   label = ~as.character(df[[var_map]]),
    #   labelOptions = labelOptions(direction = "auto")
    # ) %>%
    setView(
      lng = mean(df$Longitude, na.rm = TRUE),
      lat = mean(df$Latitude, na.rm = TRUE),
      zoom = 14
    )
}
