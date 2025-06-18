# map_module.R


render_variable_map <- function(output, result_data, var = "Air_temperature", map_id = "map") {
  output[[map_id]] <- renderLeaflet({
    df <- result_data()
    req(df)

    # Comprobar que la variable existe
    if (!var %in% names(df)) {
      return(leaflet() %>%
               addTiles() %>%
               addPopups(lng = 0, lat = 0, popup = paste("Variable", var, "no encontrada.")))
    }

    # Comprobar que las coordenadas existen
    if ("Latitude" %in% names(df) && "Longitude" %in% names(df) &&
        any(!is.na(df$Latitude)) && any(!is.na(df$Longitude))) {

      # Crear columnas auxiliares
      df$fillColor <- heat.colors(nrow(df), rev = TRUE)[rank(df[[var]])]
      df$labelText <- sprintf("%s: %s", var, round(df[[var]], 2))

      # Crear paleta
      pal <- colorNumeric(
        palette = heat.colors(256, rev = TRUE),
        domain = df[[var]]
      )

      df %>%
        leaflet() %>%
        setView(lng = mean(df$Longitude), lat = mean(df$Latitude), zoom = 12.5) %>%
        addProviderTiles("CartoDB.Positron") %>%
        addTiles() %>%
        addCircleMarkers(
          lng = ~Longitude,
          lat = ~Latitude,
          stroke = TRUE,
          weight = 1,
          color = "black",
          fillColor = ~fillColor,
          radius = 5,
          opacity = 1,
          fillOpacity = 0.7,
          label = ~labelText
        ) %>%
        addLegend(
          position = "bottomright",
          pal = pal,
          values = df[[var]],
          title = paste(var),
          opacity = 0.7
        )

    } else {
      leaflet() %>%
        addTiles() %>%
        addPopups(lng = 0, lat = 0, popup = "No coordinates to display.")
    }
  })
}
