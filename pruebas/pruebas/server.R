
library(shiny)
library(readxl)
library(openxlsx)
library(DT)
library(here)
library(magrittr)
library(dplyr)

# Cargar tu modelo personalizado
load(here("models", "MODEL_NAME.RData"))  # Asegúrate de que esto carga un objeto llamado MODEL_NAME

source("read_files/load_files.R")
source("functions/calculate_mrt.R")


function(input, output, session) {

  data <- reactiveVal(NULL)
  result_data <- reactiveVal(NULL)

  observeEvent(input$file, {
    req(input$file)

    tryCatch({
      df <- load_file(input$file)
      data(df)
      showNotification("✅ Archivo cargado correctamente", type = "message")
    }, error = function(e) {
      showNotification(paste("❌ Error leyendo el archivo:", e$message), type = "error")
      data(NULL)
    })
  })


  observeEvent(input$classify, {
    req(data())

    df <- data()

    num_vars <- c("Longitude","Latitude", "Air_temperature", "Relative_humidity", "Wind_speed", "Solar_radiation")
    for (var in num_vars) {
      if (var %in% names(df)) {
        df[[var]] <- suppressWarnings(as.numeric(gsub(",", ".", df[[var]])))
      }
    }


    if (input$utci_method == "solar") {

      df %<>%
        mutate(Radiant_temperature = calc_Tmrt(Air_temperature, Solar_radiation, Wind_speed)) %>%
        mutate(UTCI = ArchiData::UTCI(Air_temperature, Radiant_temperature, Wind_speed, Relative_humidity)) %>%
        mutate(Classification.UTCI = UTCI2classification(UTCI))

    }
    # todavia no esta implementado tener más cosas
    else if (input$utci_method == "tg") {

      df %<>%
        mutate(Radiant_temperature = ArchiData::MRT(Air_temperature, Globe_temperature, Wind_speed)) %>%
        mutate(UTCI = ArchiData::UTCI(Air_temperature, Radiant_temperature, Wind_speed, Relative_humidity)) %>%
        mutate(Classification.UTCI = UTCI2classification(UTCI))

    }  else {

      df %<>%
        mutate(UTCI = ArchiData::UTCI(Air_temperature, Radiant_temperature, Wind_speed, Relative_humidity)) %>%
        mutate(Classification.UTCI = UTCI2classification(UTCI))

    }

    # # Si no hay coordenadas, agregar columnas vacías
    # if (!input$has_geo) {
    #   df$Latitude <- NA
    #   df$Longitude <- NA
    # }
    #
    # # Actualiza el mapa
    # output$map <- renderLeaflet({
    #   df <- result_data()
    #   req(df)
    #
    #   # Ensure coordinates are present and not NA
    #   if ("Latitude" %in% names(df) && "Longitude" %in% names(df) &&
    #       any(!is.na(df$Latitude)) && any(!is.na(df$Longitude))) {
    #
    #     # Compute the color for each row using the palette
    #     pal <- colorNumeric(
    #       # palette = viridis::viridis(256, option = "B", direction = -1),
    #       palette = heat.colors(256, rev = TRUE),
    #       domain = df$Air_temperature
    #     )
    #
    #     df %>%
    #       leaflet() %>%
    #       setView(lng = mean(df$Longitude), lat = mean(df$Latitude), zoom = 12.5) %>%
    #
    #       # addMapPane("baseMap", zIndex = 410) %>%  # Create a new map pane
    #       addProviderTiles("CartoDB.Positron") %>%
    #       addTiles() %>%
    #
    #       addCircleMarkers(
    #         lng = ~Longitude,
    #         lat = ~Latitude,
    #         stroke = TRUE,
    #         weight = 1,
    #         color = "black",
    #         # fillColor = ~viridis::viridis(nrow(df), option = "B")[rank(df$Air_temperature)],
    #         fillColor = ~heat.colors(nrow(df), rev = TRUE)[rank(df$Air_temperature)],
    #         radius = 5,
    #         opacity = 1,
    #         fillOpacity = 0.7,
    #         label = ~sprintf("Air_temperature: %s", round(Air_temperature, 2))
    #       ) %>%
    #       addLegend(
    #         position = "bottomright",
    #         pal = pal,
    #         values = df$Air_temperature,
    #         title = "Air temperature (°C)",
    #         opacity = 0.7
    #       )
    #
    #   } else {
    #     leaflet() %>%
    #       addTiles() %>%
    #       addPopups(lng = 0, lat = 0, popup = "No coordinates to display.")
    #   }
    # })
    result_data(df)

  })

  output$table <- renderDT({
    req(result_data())
    datatable(result_data(), options = list(pageLength = 10))
  })

}




