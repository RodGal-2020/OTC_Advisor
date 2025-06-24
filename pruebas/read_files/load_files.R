

source("read_files/read_files.R")

load_file <- function(file) {
  ext <- tools::file_ext(file$name)
  path <- file$datapath

  if (ext == "csv") {
    df <- read_csv_data(path)
  } else if (ext == "xlsx") {
    df <- read_excel_data(path)
  } else if (ext == "zip") {
    df <- read_shapefile_zip(path)
  } else if (ext == "gpkg") {
    df <- read_gpkg_data(path)
  } else {
    stop("Formato no soportado. Usa .csv, .xlsx, .zip (shapefile) o .gpkg")
  }

  if ("Class" %in% names(df)) {
    df <- dplyr::mutate(df, Class = as.factor(Class))
  }

  return(df)
}
