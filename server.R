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
library(viridis)

source("read_files/read_files.R")
source("read_files/download_files.R")
source("functions/calculate_mrt.R")
source("functions/calculate_utci.R")
source("functions/raster_map.R")
source("models/predict_function.R")
# source("functions/map_module.R")


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
    if (!("Latitude" %in% names(df))) {
      df$Latitude <- NA
    }
    if (!("Longitude" %in% names(df))) {
      df$Longitude <- NA
    }

    # Clasificación OTC con modelo cargado
    if (!is.null(input$model) && input$model != "") {
      if(input$class == "binary") {
        df$OTC_Prediction <- predict_function(input$model, df, input$gender, input$age)
      } else if (input$class == "multiclass") {
        df$OTC_Prediction <- predict_function_multi(input$model, df, input$gender, input$age)
      }
    }

    df <- df[c("Longitude", "Latitude", setdiff(names(df), c("Longitude", "Latitude")))]


    # Guardar resultados para tabla
    result_data(df)


    # Renderizar mapa de variable elegida
    # render_variable_map(output, result_data, var = input$var_map)
  })

  output$map <- renderLeaflet({
    df <- result_data()
    if (!anyNA(df[c("Longitude", "Latitude")])) {
      raster_map(df, input$var_map, input$basemap, input$map_opacity)
    }
    else {
      return(leaflet() %>%
               addTiles() %>%
               addPopups(lng = 0, lat = 0, popup = "No coordinates to display."))
    }
  })



  output$results <- renderDT({
    df <- result_data()
    req(df)
    df %<>% mutate(across(where(is.numeric), ~ round(., 3)))
    datatable(df, options = list(scrollX = TRUE))
  })


  output$var_map_ui <- renderUI({
    df <- result_data()
    req(df)

    # Detectar columnas numéricas
    num_vars <- names(df)[sapply(df, is.numeric)]

    # Detectar columnas categóricas: factor o character
    cat_vars <- names(df)[sapply(df, function(x) is.factor(x) || is.character(x))]

    # Excluir coordenadas
    excluir <- c("Latitude", "Longitude")
    todas_vars <- setdiff(unique(c(num_vars, cat_vars)), excluir)

    selectInput(
      "var_map",
      "Variable a representar:",
      choices  = todas_vars,
      selected = "OTC_Prediction" %||% NULL  # usa la primera si hay
    )
  })



  output$download <- downloadHandler(
    filename = function() {
      paste("otc_results_", Sys.Date(), ".", input$formats, sep = "")
    },
    content = function(file) {
      df <- result_data()
      # if ("OTC_Prediction" %in% colnames(df)) {
      #   df$OTC_Prediction <- df$OTC_Prediction$.pred_class
      # }
      downloadFormats(df, input$formats, file)
    }
  )

  output$status <- renderUI({
    req(result_data())
    total_rows <- nrow(result_data())
    if (total_rows > 0) {
      p(paste("Data contains", total_rows, "records"))
    } else {
      p("No data to display.")
    }
  })
}
