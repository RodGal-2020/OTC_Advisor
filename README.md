# UTHECA OTC Classifier

## Objectives

This projects adresses the problem of classifying Outdoor Thermal Comfort (OTC) into different categories. The goal is to develop a Shiny app using within a machine learning model that can accurately classify OTC based on their features.

## Behavior

The following project can run the Shiny app that allows us to:

	- Read a Excel file with OTC data (`Air_temperature`, `Relative_humidity`, `Wind_speed`, `Solar_radiation`...)
	- Use our custom trained model, `MODEL_NAME`, to classify OTC
	- Provide the classification using other classifiers, such as PET and UTCI
	- Use different buttons to modify the custom readings:
	  - ¿Is `MRT` available or only `Solar_radiation`?
	  - ¿Does the data include geographic coordinates?
	- Export the results in a Excel file, including our prediction of the OTC

## Setup

Just open the .Rproj file and launch the following:

```{r}
renv::install("remotes")
remotes::install_github("RodGal-2020/ArchiData")
renv::restore()
```

Then, run the app with:

```{r}
shiny::runApp("server")
```

## Descripción completa

### 🧭 Propósito de la herramienta OTC_Advisor
OTC_Advisor es una aplicación interactiva desarrollada en R Shiny destinada a evaluar y visualizar el confort térmico en espacios exteriores urbanos. La herramienta permite cargar datos meteorológicos (tanto medidos como obtenidos de fuentes alternativas), aplicar modelos de clasificación de confort térmico, visualizar los resultados geográficamente mediante mapas dinámicos, y exportar los resultados en múltiples formatos. Su enfoque modular permite a urbanistas, investigadores y técnicos evaluar rápidamente la sensación térmica percibida en distintas ubicaciones y momentos, favoreciendo decisiones sobre diseño urbano, mitigación climática o intervención ambiental.

### ✅ Objetivos del desarrollo, ordenados por prioridad y dificultad

✅ 1. Carga de datos desde archivos Excel (.xlsx)
Permitir al usuario subir datasets locales con variables climáticas estándar.

✅ 2. Clasificación del confort térmico con un modelo base
Implementar un modelo predictivo simple XGB para clasificar el confort térmico. Siguientes pasos en objetivo 6.
	- Clasificación binaria
	- Clasificación multiclase
	- Entrenado en RUROS

✅ 3. Visualización en mapa con leaflet
Mostrar los resultados del modelo como puntos geolocalizados sobre un mapa interactivo.

4. Opciones básicas de visualización
Añadir controles para ajustar propiedades del mapa como 
	- ✅ transparencia del fondo
	- ✅ ancho de la rejilla (amplitud de las coordenadas / tamaño de los cuadraditos)

✅ 5. Exportación de resultados en diferentes formatos
Permitir la descarga de datos clasificados en varios formatos: Excel, CSV, GeoJSON.
    - ✅ **POSIBILIDAD DE DESCARGA EN EXCEL, CSV, TXT Y GEOPACKAGE**

6. Implementación de diferentes modelos de predicción
Permitir al usuario elegir entre distintos algoritmos de clasificación (e.g., Random Forest, SVM, regresión logística, modelos basados en MRT, etc.).

7. Mejora de la interfaz:
	- Barra de status
	- Barra de la izquierda
	- Convertir selects en desplegables
	- Colores y estilo general

8. Pedir feedback

8. Interpolación espacial
Incorporar un modelo de interpolación para estimar valores de confort térmico en áreas sin mediciones directas.
	- ✅ KNN con K = 1
	- KNN con K = ¿?
	- Kriging/IDW/otros

### Extra
9. Conexión con fuentes de datos alternativas (como Weather Underground)
Integrar API externas para importar datos meteorológicos automáticamente y complementar la información local.

10. Filtros por fecha, hora o tipo de modelo
Añadir opciones interactivas para filtrar los datos por rango temporal, condiciones meteorológicas específicas o el modelo usado.
