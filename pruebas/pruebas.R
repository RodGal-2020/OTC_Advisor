library(shiny)
library(readxl)
library(DT)

ui <- fluidPage(
  titlePanel("Verificador de carga de archivo"),
  sidebarLayout(
    sidebarPanel(
      fileInput("file", "📤 Subir archivo (.csv o .xlsx)",
                accept = c(".csv", ".xlsx"))
    ),
    mainPanel(
      DTOutput("table")
    )
  )
)

server <- function(input, output, session) {

  data <- reactive({
    req(input$file)

    ext <- tools::file_ext(input$file$name)

    tryCatch({
      df <- switch(ext,
                   csv = read.csv(input$file$datapath, stringsAsFactors = FALSE),
                   xlsx = read_excel(input$file$datapath),
                   stop("Formato de archivo no soportado.")
      )
      return(df)
    }, error = function(e) {
      showNotification(paste("Error leyendo el archivo:", e$message), type = "error")
      return(NULL)
    })
  })

  output$table <- renderDT({
    req(data())
    datatable(data(), options = list(pageLength = 10))
  })
}

shinyApp(ui, server)
