library(shiny)
library(readxl)
library(openxlsx)
library(DT)
library(here)

# Cargar tu modelo personalizado
load(here("models", "MODEL_NAME.RData"))  # Asegúrate de que esto carga un objeto llamado MODEL_NAME

function(input, output, session) {

  data <- reactiveVal(NULL)
  result_data <- reactiveVal(NULL)

  observeEvent(input$file, {
    req(input$file)
    df <- read_excel(input$file$datapath)

      # Clean the data
      df %<>% mutate(Class = as.factor(Class))

    data(df)
  })

  observeEvent(input$classify, {
    req(data())

    df <- data()

    # Si no hay RT, estimarlo a partir de radiación solar
    if (!input$has_mrt && "Solar_radiation" %in% names(df)) {
      df %<>%
        mutate(RT = ArchiData::MRT(T_a, GT, V)) %>%
        mutate(UTCI = ArchiData::UTCI(T_a, RT, V, RH)) %>%
        mutate(Clasificación.UTCI = UTCI2classification(UTCI))
    }

    # Si no hay coordenadas, agregar columnas vacías
    if (!input$has_geo) {
      df$Latitude <- NA
      df$Longitude <- NA
    }

    # Clasificación OTC
    df$OTC_Prediction <- MODEL_NAME %>% predict(df)

    result_data(df)

    # Actualiza el mapa
    output$map <- renderLeaflet({
      df <- result_data()
      req(df)

      # Ensure coordinates are present and not NA
      if ("Latitude" %in% names(df) && "Longitude" %in% names(df) &&
          any(!is.na(df$Latitude)) && any(!is.na(df$Longitude))) {

        # Compute the color for each row using the palette
        palette_func <- colorFactor(
          palette = sample(colors(), nrow(unique(df$OTC_Prediction)), replace = TRUE),
          domain = df$OTC_Prediction[[1]]
        )

        df$color <- palette_func(df$OTC_Prediction)

        leaflet(df) %>%
          addTiles() %>%
          addCircleMarkers(
            lng = ~Longitude,
            lat = ~Latitude,
            color = ~color,
            radius = 6,
            stroke = FALSE,
            fillOpacity = 0.8,
            popup = ~paste("OTC:", OTC_Prediction)
          )
      } else {
        leaflet() %>%
          addTiles() %>%
          addPopups(lng = 0, lat = 0, popup = "No coordinates to display.")
      }
    })


  })

  # Definir una paleta de colores para OTC Prediction
  pal <- reactive({
    colorFactor(palette = c("blue", "green", "red"), domain = result_data()$OTC_Prediction)
  })

  output$results <- renderDT({
    req(result_data())
    datatable(result_data(), options = list(scrollX = TRUE))
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
