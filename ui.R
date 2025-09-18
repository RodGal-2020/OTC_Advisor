library(shinydashboard)
library(shiny)
library(readxl)
library(DT)
library(leaflet)

header <- dashboardHeader(title = "OTC Classifier")

sidebar <- dashboardSidebar(
  width = 300,
  fileInput("file", "📤 Upload Excel, CSV, ZIP File with Shapefiles or Geopackage", accept = c(".xlsx", ".csv", ".zip", ".gpkg")),
  # checkboxInput("utci", "🌡️Do you want to calculate the UTCI?", value = FALSE),
  actionButton("calculate_utci", "Only Calculate UTCI", class = "btn-primary"),
  radioButtons("class",
               label = tags$span("Select classification:",
                                 title = "Choose between the predicted comfort probability (Binary) or the predicted comfort class (Multiclass)."),
               choices = c(
                 "Binary" = "binary",
                 "Multiclass" = "multiclass"
               ),
               selected = "binary"),
  radioButtons("model",
               label = tags$span("Select model:",
                                 title = "Choose the algorithm used for prediction."),
               choices = c(
                 "Naive-Bayes" = "NBD",
                 "XGBoost" = "XGB"
               ),
               selected = "XGB"),


  # ---- Para XGBoost y Naive-Bayes ----
  conditionalPanel(
    condition = "input.model == 'XGB' || input.model == 'NBD'",

    selectInput("gender", "Select your gender",
                choices = c("Male", "Female")),
    selectInput("age", "Select your age",
                choices = c("<12","13-17", "18-24", "25-34", "35-44", "45-54", "55-64", ">65")),
    selectInput("clo", "Select your clothings",
                choices = c("Light short-sleeved T-shirt and shorts",
                            "Long-sleeved T-shirt or polo with light trousers",
                            "Long-sleeved shirt + lightweight long trousers",
                            "Office wear: shirt, long trousers, light jacket",
                            "Full business suit (shirt, jacket, trousers)",
                            "Warmer clothing")),
    selectInput("met_rate", "Select your metabolic rate",
                choices = c("Seated relaxed",
                            "Standing",
                            "Walking",
                            "Bicycling",
                            "Running")),
    selectInput("season", "Select the season",
                choices = c("Summer","Autumn", "Winter", "Spring")),
  ),
  actionLink("more_info_model", "More information", icon = icon("info-circle")),
  br(),
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
               uiOutput("var_map_ui"),

               selectInput("basemap", "Select base map",
                           choices = c("OSM", "Satélite", "Esri")),

               sliderInput("map_opacity", "Map opacity:", min = 0, max = 1, value = 0.5, step = 0.1),
               sliderInput("n_raster", "Raster resolution:", min = 20, max = 200, value = 50, step = 10),
               sliderInput("buffer_radius", "Buffer radius around data (m):", min = 100, max = 1000, value = 200, step = 50),
           ),

           box(title = "📌 Status", width = NULL, status = "warning", solidHeader = TRUE, collapsible = TRUE,
               uiOutput("status")
           ),

           box(title = "⬇️ Download Results", width = NULL, status = "primary", solidHeader = TRUE, collapsible = TRUE, collapsed = TRUE,
               radioButtons("formats", "Download Formats:",
                            choices = c(
                              "CSV" = "csv",
                              "Excel" = "xlsx",
                              "Plain text (txt)" = "txt",
                              # "Shapefiles" = "zip",
                              "Geopackage" = "gpkg"
                            ),
                            selected = "xlsx"),
               downloadButton("download", "Download" ),

           ),

           box(title = "🌍 Download Map", width = NULL, status = "primary", solidHeader = TRUE, collapsible = TRUE, collapsed = TRUE,
               downloadButton("download_map", "Download map (HTML)")
           )

    )

  )
)




dashboardPage(
  header,
  sidebar,
  body
)
