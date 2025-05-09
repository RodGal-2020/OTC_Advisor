library(shinydashboard)
library(shiny)
library(readxl)
library(DT)
library(leaflet)

header <- dashboardHeader(title = "OTC Classifier")

sidebar <- dashboardSidebar(
  fileInput("file", "Upload Excel File", accept = ".xlsx"),
  checkboxInput("has_mrt", "Includes MRT", value = TRUE),
  checkboxInput("has_geo", "Includes Coordinates", value = TRUE),
  actionButton("classify", "Classify OTC"),
  downloadButton("download", "Download Results")
)

body <- dashboardBody(
  fluidRow(
    column(width = 9,
           box(width = NULL, solidHeader = TRUE,
               leafletOutput("map", height = 500)
           ),
           box(width = NULL,
               DTOutput("results")
           )
    ),
    column(width = 3,
           box(width = NULL, status = "warning",
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
