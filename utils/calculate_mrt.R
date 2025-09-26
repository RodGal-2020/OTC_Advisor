# Paquetes necesarios
if (!require("dplyr")) install.packages("dplyr")
library(dplyr)
library(ArchiData)

# puedes usar una fórmula simplificada basada en ISO 7726, que aproxima Tmrt en función de la radiación solar, considerando un cuerpo expuesto en campo abierto (sin sombra). Este método es útil cuando no se dispone de geometría urbana ni modelos como RayMan o SOLWEIG.

# Función para calcular Tmrt (simplificada)
calc_Tmrt <- function(air_temp, solar_rad, wind_speed, absorptivity = 0.7, emissivity = 0.95) {
  # air_temp: temperatura del aire en °C
  # solar_rad: radiación solar global en W/m²
  # wind_speed: velocidad del viento en m/s

  # Constantes
  # absorptivity <- 0.7  # fracción de radiación absorbida por el cuerpo
  # emissivity <- 0.95   # emisividad del cuerpo humano
  stefan_boltzmann <- 5.67e-8  # constante SB en W/m²K⁴

  # Calcular incremento por radiación solar
  solar_gain <- (absorptivity * solar_rad) / (emissivity * stefan_boltzmann)

  # Ajustar por efecto convectivo del viento (fórmula empírica)
  delta_Tmrt <- (solar_gain / (1 + 0.26 * wind_speed))^(0.25) - 273.15

  # Tmrt final
  Tmrt <- air_temp + delta_Tmrt
  return(Tmrt)
}


