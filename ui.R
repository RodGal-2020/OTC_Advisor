library(shinydashboard)
library(shiny)
library(readxl)
library(DT)
library(leaflet)

header <- dashboardHeader(title = "OTC Classifier")

sidebar <- dashboardSidebar(
  fileInput("file", "📤 Upload Excel File", accept = ".xlsx"),
  checkboxInput("has_mrt", "✔ Includes MRT", value = TRUE),
  checkboxInput("has_geo", "✔ Includes Coordinates", value = TRUE),
  actionButton("classify", "⚙️ Classify OTC", class = "btn-primary"),
  br(), br(),
  downloadButton("download", "⬇️ Download Results")
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
           box(title = "📌 Status", width = NULL, status = "warning", solidHeader = TRUE,
               uiOutput("status")
           )
    )
  )
)

dashboardPage(
  header,
  sidebar,
  body
)
