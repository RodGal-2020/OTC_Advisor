

## Pasar a Shapefile

# Cargar paquetes necesarios
library(sf)
library(dplyr)
library(terra)

# Leer como tabla
df <- read.csv2("OTC_data.csv", stringsAsFactors = FALSE, sep = ";")

# Convertir a objeto espacial sf
puntos_sf <- st_as_sf(df, coords = c("Longitude", "Latitude"), crs = 4326)

# Exportar como shapefile (se crea un conjunto de archivos .shp, .dbf, etc.)
st_write(puntos_sf, "OTC_classification.shp", delete_dsn = TRUE)


temp_zip <- tempfile(fileext = ".zip")
downloadFormats(df, "shp", temp_zip)
browseURL(temp_zip)  # Debería abrir el ZIP generado

