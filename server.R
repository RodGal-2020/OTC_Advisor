library(shiny)
library(readxl)
library(openxlsx)
library(DT)
library(here)
library(magrittr)
library(dplyr)
library(terra)
library(gstat)
library(FNN)

# Cargar tu modelo personalizado
load(here("models", "MODEL_NAME.RData"))  # Asegúrate de que esto carga un objeto llamado MODEL_NAME

source("read_files/load_files.R")
source("functions/calculate_mrt.R")
source("functions/calculate_utci.R")
source("functions/map_module.R")


function(input, output, session) {

  data <- reactiveVal(NULL)
  result_data <- reactiveVal(NULL)
  result_data_raster <- reactiveVal(NULL)  # para guardar el raster

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

    # Convertir numéricas
    num_vars <- c("Longitude","Latitude", "Air_temperature", "Relative_humidity", "Wind_speed", "Solar_radiation")
    for (var in num_vars) {
      if (var %in% names(df)) {
        df[[var]] <- suppressWarnings(as.numeric(gsub(",", ".", df[[var]])))
      }
    }

    # Calcular UTCI y su clasificación
    df <- calc_utci(df, input$utci_method)

    # Si no hay coordenadas, rellenar con NA
    if (!input$has_geo) {
      df$Latitude <- NA
      df$Longitude <- NA
    }

    # Clasificación OTC con modelo cargado
    df$OTC_Prediction <- predict(MODEL_NAME, df)

    # Guardar resultados para tabla
    result_data(df)


    # Renderizar mapa de variable elegida
    # render_variable_map(output, result_data, var = input$var_map)
  })

  output$map <- renderLeaflet({
    df <- result_data()
    req(df)
    req(input$var_map)  # variable a mapear

    if (!input$has_geo || !("Latitude" %in% names(df)) || !("Longitude" %in% names(df))) {
      return(leaflet() %>%
               addTiles() %>%
               addPopups(lng = 0, lat = 0, popup = "No coordinates to display."))
    }

    # Crear sf con coordenadas
    sf_points <- sf::st_as_sf(df, coords = c("Longitude", "Latitude"), crs = 4326)

    # Crear cuadrícula (malla regular) sobre el rango de las coordenadas
    lon_range <- range(df$Longitude, na.rm = TRUE)
    lat_range <- range(df$Latitude, na.rm = TRUE)
    n <- 50  # resolución de la cuadrícula

    amp <- 0.05
    grid_df <- expand.grid(
      Longitude = seq(lon_range[1]-amp, lon_range[2]+amp, length.out = n*5),
      Latitude = seq(lat_range[1]-amp, lat_range[2]+amp, length.out = n*5)
    )
    sf_grid <- sf::st_as_sf(grid_df, coords = c("Longitude", "Latitude"), crs = 4326)

    # Calcular el valor de la variable seleccionada para cada punto de la cuadrícula
    # asignando el valor del punto más cercano (nearest neighbor)
    coords_data <- sf::st_coordinates(sf_points)
    coords_grid <- sf::st_coordinates(sf_grid)

    # Encontrar el índice del vecino más cercano para cada punto de la cuadrícula
    nn <- get.knnx(coords_data, coords_grid, k = 1)

    # Extraer los valores de la variable seleccionada en df
    var_values <- df[[input$var_map]]

    # Asignar a cada punto de la cuadrícula el valor del vecino más cercano
    grid_values <- var_values[nn$nn.index]

    # Añadir los valores al sf_grid
    sf_grid[[input$var_map]] <- grid_values

    # Convertir a SpatialPointsDataFrame para rasterización
    sp_grid <- as(sf_grid, "Spatial")

    # Convertir sf_grid a SpatVector de terra
    sv <- vect(sf_grid)

    # Crear raster vacío con la extensión de los puntos y resolución n x n
    r <- rast(ext(sv), ncol = n, nrow = n, crs = "EPSG:4326")

    # Rasterizar usando el campo seleccionado
    r <- rasterize(sv, r, field = input$var_map)

    # Paleta de colores
    valores <- values(r)
    pal <- colorNumeric("viridis", domain = range(valores, na.rm = TRUE), , na.color = "#000000")


    map_provider <- switch(input$basemap,
                           "OSM" = providers$OpenStreetMap.Mapnik,
                           "Satélite" = providers$Esri.WorldImagery,
                           "Esri" = providers$Esri.WorldGrayCanvas,
                           "Stadia" = providers$Stadia.AlidadeSmooth)

    leaflet() %>%
      addProviderTiles(map_provider) %>%
      addRasterImage(r, colors = pal, opacity = 0.4) %>%
      addLegend(pal = pal, values = values(r), title = input$var_map, position = "bottomright") %>%
      setView(lng = mean(df$Longitude, na.rm = TRUE), lat = mean(df$Latitude, na.rm = TRUE), zoom = 13)
  })



  output$results <- renderDT({
    df <- result_data()
    req(df)
    df %<>% mutate(across(where(is.numeric), ~ round(., 3)))
    datatable(df, options = list(scrollX = TRUE))
  })

  output$download <- downloadHandler(
    filename = function() {
      paste("otc_results_", Sys.Date(), ".xlsx", sep = "")
    },
    content = function(file) {
      write.xlsx(result_data(), file)
    }
  )

  output$status <- renderUI({
    req(result_data())
    total_rows <- nrow(result_data())
    if (total_rows > 0) {
      p(paste("Data contains", total_rows, "records and",
              ifelse(input$has_geo, "includes", "does not include"),
              "geographic coordinates."))
    } else {
      p("No data to display.")
    }
  })
}
