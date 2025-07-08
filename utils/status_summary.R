status_summary <- function(df) {
  req(df)
  total_rows <- nrow(df)

  # Variables numéricas
  vars_num <- c("Air_temperature", "Globe_temperature", "Relative_humidity",
                "Wind_speed", "Radiant_temperature", "UTCI", "OTC_Probability")

  numeric_summary_rows <- lapply(vars_num, function(var) {
    if (var %in% names(df)) {
      vals <- suppressWarnings(as.numeric(df[[var]]))
      if (!all(is.na(vals))) {
        tags$tr(
          tags$td(var),
          tags$td(round(min(vals, na.rm = TRUE), 1)),
          tags$td(round(mean(vals, na.rm = TRUE), 1)),
          tags$td(round(max(vals, na.rm = TRUE), 1))
        )
      } else {
        tags$tr(tags$td(var), tags$td(colspan = 3, "No numeric values"))
      }
    } else {
      tags$tr(tags$td(var), tags$td(colspan = 3, "Not found"))
    }
  })

  # Variables categóricas
  vars_cat <- c("Classification.UTCI", "OTC_Prediction")

  categorical_summary_rows <- lapply(vars_cat, function(var) {
    if (var %in% names(df)) {
      moda <- names(sort(table(df[[var]]), decreasing = TRUE))[1]
      tags$tr(tags$td(var), tags$td(moda))
    } else {
      tags$tr(tags$td(var), tags$td("Not found"))
    }
  })

  # UI con estilo compacto
  tagList(
    tags$p(paste("Data contains", total_rows, "records."), class = "text-lg"),

    tags$h5("Numeric summary", class = "text-lg"),
    tags$table(class = "table table-bordered table-striped table-sm text-sm",
               tags$thead(
                 tags$tr(
                   tags$th("Variable"),
                   tags$th("Min"),
                   tags$th("Mean"),
                   tags$th("Max")
                 )
               ),
               tags$tbody(numeric_summary_rows)
    ),

    tags$h5("Categorical summary", class = "text-lg"),
    tags$table(class = "table table-bordered table-striped table-sm text-sm",
               tags$thead(
                 tags$tr(
                   tags$th("Variable"),
                   tags$th("Most frequent value")
                 )
               ),
               tags$tbody(categorical_summary_rows)
    )
  )
}


