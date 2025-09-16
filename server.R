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
source("utils/calculate_mrt.R")
source("utils/calculate_utci.R")
source("utils/status_summary.R")
source("utils/raster_map2.R")
source("models/predict_function.R")
# source("utils/map_module.R")


function(input, output, session) {

  data <- reactiveVal(NULL)
  result_data <- reactiveVal(NULL)
  result_data_raster <- reactiveVal(NULL)  # para guardar el raster

  observeEvent(input$file, {
    req(input$file)

    tryCatch({
      df <- load_file(input$file)
      data(df)
      showNotification("✅ File uploaded successfully", type = "message")
    }, error = function(e) {
      showNotification(paste("❌ Error reading file:", e$message), type = "error")
      data(NULL)
    })
  })

  observeEvent(input$calculate_utci, {
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
    df <- calc_utci(df)

    # Si no hay coordenadas, rellenar con NA
    if (!("Latitude" %in% names(df))) {
      df$Latitude <- NA
    }
    if (!("Longitude" %in% names(df))) {
      df$Longitude <- NA
    }
    df <- df[c("Longitude", "Latitude", setdiff(names(df), c("Longitude", "Latitude")))]


    # Guardar resultados para tabla
    result_data(df)
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
    # if (input$utci) {df <- calc_utci(df)}

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
        df$OTC_Probability <- predict_function(input$model, df, input$gender, input$age)*100
      } else if (input$class == "multiclass") {
        df$OTC_Prediction <- predict_function_multi(input$model, df, input$gender, input$age)
        niveles_otc <- c("Very cold", "Cold", "Neither cool nor warm", "Warm", "Very hot")
        df$OTC_Prediction <- factor(df$OTC_Prediction, levels = niveles_otc)
      }
    }

    df <- df[c("Longitude", "Latitude", setdiff(names(df), c("Longitude", "Latitude")))]


    # Guardar resultados para tabla
    result_data(df)


    # Renderizar mapa de variable elegida
    # render_variable_map(output, result_data, var = input$var_map)
  })

  map_leaflet <- reactive({
    df <- result_data()
    if (!anyNA(df[c("Longitude", "Latitude")])) {
      raster_map(df, input$var_map, input$basemap, input$map_opacity, n = input$n_raster, buffer_dist = input$buffer_radius)
    } else {
      leaflet() %>%
        addTiles() %>%
        addPopups(lng = 0, lat = 0, popup = "No coordinates to display.")
    }
  })

  output$map <- renderLeaflet({
    map_leaflet()
  })

  output$download_map <- downloadHandler(
    filename = function() {
      paste0("map_", Sys.Date(), ".html")
    },
    content = function(file) {
      htmlwidgets::saveWidget(
        widget = map_leaflet(),
        file = file,
        selfcontained = TRUE
      )
    }
  )

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

    todas_vars <- c(num_vars, cat_vars)  # ordenar alfabéticamente
    # Vector de opciones filtradas
    opciones <- intersect(todas_vars, c("Air_temperature", "Globe_temperature", "Relative_humidity", "Wind_speed", "Radiant_temperature", "UTCI", "Classification.UTCI", "OTC_Probability", "OTC_Prediction"))

    # Buscar la primera que empiece por "OTC"
    seleccion_otc <- grep("^OTC", opciones, value = TRUE)[1]
    seleccion_utci <- grep("UTCI", opciones, value = TRUE)[1]


    # Construcción del selectInput
    selectInput(
      "var_map",
      "Variable to be represented:",
      choices  = opciones,
      selected = seleccion_otc  %||% seleccion_utci %||% opciones[1]  # si no hay ninguna "OTC", usa la primera
    )
  })

  observeEvent(input$more_info_model, {
    showModal(modalDialog(
      title = "Model information",
      HTML("
      <b>Naive-Bayes:</b> A simple probabilistic model based on Bayes’ theorem. It assumes independence between predictors and works well with small datasets.<br><br>
      <b>XGBoost:</b> An advanced ensemble learning algorithm based on gradient boosting. It is highly accurate and efficient, especially for structured data.<br>
    "),
      easyClose = TRUE,
      footer = modalButton("Close")
    ))
  })


  output$download <- downloadHandler(
    filename = function() {
      paste("otc_results_", Sys.Date(), ".", input$formats, sep = "")
    },
    content = function(file) {
      df <- result_data()
      downloadFormats(df, input$formats, file)
    }
  )

  output$status <- renderUI({
    req(result_data())
    status_summary(result_data())
  })

}
