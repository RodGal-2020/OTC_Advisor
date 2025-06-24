

# Descargas en diferentes formatos

library(sf)
library(dplyr)
library(terra)

downloadFormats <- function(data, extension, filename) {
  # Exportar según formato
  switch(extension,

         # CSV
         csv = write.csv(data, filename, row.names = FALSE),

         # Excel
         xlsx = write.xlsx(data, filename, rowNames = FALSE),

         # Texto
         txt = write.table(data, filename, sep = "\t", row.names = FALSE),

         # Shapefile (en zip)
         zip = {
           # Crear carpeta temporal
           dir_temp <- tempdir()
           layer_name <- "shapefile_export"

           # Crear objeto sf
           puntos_sf <- st_as_sf(data, coords = c("Longitude", "Latitude"), crs = 4326)

           # Acortar nombres de columnas a 10 caracteres
           names(puntos_sf) <- substr(names(puntos_sf), 1, 10)

           # Ruta del shapefile sin extensión
           ruta_base <- file.path(dir_temp, layer_name)

           # Escribir shapefile
           st_write(puntos_sf, dsn = ruta_base, driver = "ESRI Shapefile", delete_layer = TRUE, quiet = TRUE)

           # Listar todos los archivos generados (.shp, .shx, .dbf, .prj...)
           shp_files <- list.files(dir_temp, pattern = paste0(layer_name, "\\."), full.names = TRUE)

           # Crear ZIP directamente en el archivo temporal `filename`
           zip(zipfile = filename, files = shp_files, flags = "-j")
         },

         # GeoPackage
         gpkg = {
           puntos_sf <- st_as_sf(data, coords = c("Longitude", "Latitude"), crs = 4326)
           st_write(puntos_sf, filename, delete_dsn = TRUE, quiet = TRUE)
         },

         stop("Extensión no soportada")
  )
}








































