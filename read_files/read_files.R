
read_csv_data <- function(path) {
  first_lines <- readLines(path, n = 5, warn = FALSE)
  sep <- if (sum(grepl(";", first_lines)) > sum(grepl(",", first_lines))) ";" else ","
  read.csv(path, sep = sep, stringsAsFactors = FALSE)
}


read_excel_data <- function(path) {
  readxl::read_excel(path)
}



read_shapefile_zip <- function(path) {
  temp_dir <- tempdir()
  unzip(path, exdir = temp_dir)

  shp_file <- list.files(temp_dir, pattern = "\\.shp$", full.names = TRUE)
  if (length(shp_file) == 0) stop("No se encontró ningún archivo .shp dentro del .zip")

  sf_data <- sf::st_read(shp_file[1], quiet = TRUE)

  sf_data %>%
    mutate(Longitude = sf::st_coordinates(.)[,1],
           Latitude = sf::st_coordinates(.)[,2]) %>%
    sf::st_drop_geometry() %>%
    rename(
      Air_temperature = Ar_tmpr,
      Relative_humidity = Rltv_hm,
      Wind_speed = Wnd_spd,
      Solar_radiation = Slr_rdt
    )
}


read_gpkg_data <- function(path) {
  sf_data <- sf::st_read(path, quiet = TRUE)

  sf_data %>%
    mutate(Longitude = sf::st_coordinates(.)[,1],
           Latitude = sf::st_coordinates(.)[,2]) %>%
    sf::st_drop_geometry()
}


load_file <- function(file) {
  ext <- tools::file_ext(file$name)
  path <- file$datapath

  df <- switch(
    ext,
    csv  = read_csv_data(path),
    xlsx = read_excel_data(path),
    zip  = read_shapefile_zip(path),
    gpkg = read_gpkg_data(path),
    stop("Formato no soportado. Usa .csv, .xlsx, .zip (shapefile) o .gpkg")
  )


  if ("Class" %in% names(df)) {
    df <- dplyr::mutate(df, Class = as.factor(Class))
  }

  return(df)
}

