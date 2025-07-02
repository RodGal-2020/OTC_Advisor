library(shinydashboard)
library(shiny)
library(readxl)
library(DT)
library(leaflet)

header <- dashboardHeader(title = "OTC Classifier")

sidebar <- dashboardSidebar(
  fileInput("file", "📤 Upload Excel, CSV or ZIP File", accept = c(".xlsx", ".csv", ".zip", ".gpkg")),

  selectInput("gender", "Select your gender",
              choices = c("Male", "Female")),
  selectInput("age", "Select your age",
              choices = c("<12","13-17", "18-24", "25-34", "35-44", "45-54", "55-64", ">65")),
  radioButtons("utci_method", "🌡️ UTCI Source:",
               choices = c(
                 "Includes UTCI column" = "utci",
                 "Includes MRT column" = "mrt",
                 "Calculate from Globe Temperature" = "tg",
                 "Calculate from Solar Radiation" = "solar"
               ),
               selected = "tg"),
  br(),
  radioButtons("class", "Select classification:",
               choices = c(
                 "Binary (Comfort/Discomfort)" = "binary",
                 "Multiclass" = "multiclass"
               ),
               selected = "binary"),
  radioButtons("model", "Select model:",
               choices = c(
                 "Naive-Bayes" = "NBD",
                 "XGBoost" = "XGB"
               ),
               selected = "xlsx"),
  actionButton("classify", "⚙️ Classify OTC", class = "btn-primary"),
  br(), br(),

  leafletOutput("map")
)


body <- dashboardBody(
  tags$head(
    tags$style(HTML("
      .box-header .box-title {
        font-weight: bold;
        font-size: 16px;
      }
      .leaflet-container {
        background: #f9f9f9;
      }
    "))
  ),

  fluidRow(
    column(width = 9,
           box(title = "🗺️ Map of Classified Data", width = NULL, solidHeader = TRUE, status = "primary", collapsible = TRUE,
               leafletOutput("map", height = 500)
           ),
           box(title = "📋 Results Table", width = NULL, solidHeader = TRUE, status = "info", collapsible = TRUE,
               DTOutput("results")
           )
    ),
    column(width = 3,
           box(title = "🧭 Map Options", width = NULL, status = "success", solidHeader = TRUE,
               # selectInput("var_map", "Variable a representar:",
               #             choices = c("Air_temperature", "Relative_humidity", "Wind_speed", "UTCI"), selected = "Air_temperature"),
               uiOutput("var_map_ui"),

               selectInput("basemap", "Selecciona mapa base",
                           choices = c("Stadia", "Satélite", "Esri", "OSM")),

               sliderInput("map_opacity", "Opacidad del mapa:", min = 0, max = 1, value = 0.5, step = 0.1),
           ),

           box(title = "📌 Status", width = NULL, status = "warning", solidHeader = TRUE,
               uiOutput("status")
           ),

           box(title = "⬇️ Download Results", width = NULL, status = "primary", solidHeader = TRUE,
               radioButtons("formats", "Download Formats:",
                            choices = c(
                              "CSV" = "csv",
                              "Excel" = "xlsx",
                              "Texto plano (txt)" = "txt",
                              # "Shapefiles" = "zip",
                              "Geopackage" = "gpkg"
                            ),
                            selected = "xlsx"),
               downloadButton("download", "Download" ),
           ),

    )

  )
)




dashboardPage(
  header,
  sidebar,
  body
)
