

library(shiny)
library(readxl)
library(DT)

ui <- fluidPage(
  titlePanel("Verificador de carga de archivo"),
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "Sube un CSV, Excel o ZIP con shapefile",
                accept = c(".csv", ".xlsx", ".zip")),
      radioButtons("utci_method", "🌡️ UTCI Source:",
                   choices = c(
                     "Includes MRT column" = "mrt",
                     "Calculate from Globe Temperature" = "tg",
                     "Calculate from Solar Radiation" = "solar"
                   ),
                   selected = "mrt"),
      actionButton("classify", "⚙️ Classify OTC", class = "btn-primary")
    ),
    mainPanel(
      DTOutput("table")
    )
  )
)


#
# sidebar <- dashboardSidebar(
#   fileInput("file", "📤 Upload Excel, CSV or ZIP File", accept = c(".xlsx", ".csv", ".zip", ".gpkg")),
#
#   radioButtons("utci_method", "🌡️ UTCI Source:",
#                choices = c(
#                  "Includes MRT column" = "mrt",
#                  "Calculate from Globe Temperature" = "tg",
#                  "Calculate from Solar Radiation" = "solar"
#                ),
#                selected = "mrt"),
#
#   checkboxInput("has_geo", "✔ Includes Coordinates", value = TRUE),
#   actionButton("classify", "⚙️ Classify OTC", class = "btn-primary"),
#   br(), br(),
#   downloadButton("download", "⬇️ Download Results")
# )
