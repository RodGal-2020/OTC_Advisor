library(shiny)
library(readxl)
library(openxlsx)
library(DT)
library(here)
library(magrittr)
library(dplyr)

# Cargar tu modelo personalizado
load(here("models", "MODEL_NAME.RData"))  # Asegúrate de que esto carga un objeto llamado MODEL_NAME

function(input, output, session) {

  data <- reactiveVal(NULL)
  result_data <- reactiveVal(NULL)

  observeEvent(input$file, {
    req(input$file)
    df <- read_excel(input$file$datapath)

      # Clean the data
      df %<>%
        mutate(Class = as.factor(Class))

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
        pal <- colorNumeric(
          # palette = viridis::viridis(256, option = "B", direction = -1),
          palette = heat.colors(256, rev = TRUE),
          domain = df$Air_temperature
        )

        df %>%
          leaflet() %>%
            setView(lng = mean(df$Longitude), lat = mean(df$Latitude), zoom = 12.5) %>%

            # addMapPane("baseMap", zIndex = 410) %>%  # Create a new map pane
            addProviderTiles("CartoDB.Positron") %>%
            addTiles() %>%

            addCircleMarkers(
              lng = ~Longitude,
              lat = ~Latitude,
              stroke = TRUE,
              weight = 1,
              color = "black",
              # fillColor = ~viridis::viridis(nrow(df), option = "B")[rank(df$Air_temperature)],
              fillColor = ~heat.colors(nrow(df), rev = TRUE)[rank(df$Air_temperature)],
              radius = 5,
              opacity = 1,
              fillOpacity = 0.7,
              label = ~sprintf("Air_temperature: %s", round(Air_temperature, 2))
            ) %>%
          addLegend(
            position = "bottomright",
            pal = pal,
            values = df$Air_temperature,
            title = "Air temperature (°C)",
            opacity = 0.7
          )

      } else {
        leaflet() %>%
          addTiles() %>%
          addPopups(lng = 0, lat = 0, popup = "No coordinates to display.")
      }
    })


  })

  output$results <- renderDT({
    req(result_data())
    df <- result_data()
    data_table <- df %>% mutate(across(all_numeric(), ~ round(., 3)))
    datatable(data_table , options = list(scrollX = TRUE))
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
