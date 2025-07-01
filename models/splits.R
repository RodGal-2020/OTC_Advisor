
library(readxl)
library(tidyverse)
library(tidymodels)
library(readxl)
library(themis)
library(kableExtra)
library(ranger)

# Cargar y preparar los datos
utheca <- read_excel("templates/utheca_adaptado.xlsx")

utheca <- utheca %>%
  mutate(across(where(~is.character(.)), as.factor)) # Convertir a factor

# Crar variable Comfort y Discomfort para equilibrar las clases
utheca <- utheca %>%
  mutate(GROUP = case_when(
    Subjective.well.being.sensation %in% c("Comfortable", "Very comfortable") ~ "Comfort",
    Subjective.well.being.sensation %in% c("Slightly uncomfortable", "Quite uncomfortable", "Uncomfortable") ~ "Discomfort"
  )) %>%
  mutate(GROUP = factor(GROUP, levels = c("Comfort", "Discomfort")))

utheca <- utheca %>%
  select(Air.temperature,Globe.temperature,Relative.humidity,Wind.speed,Gender,BMI,Age.range,GROUP) # Eliminar la columna original

set.seed(2302) # Fijar semilla para reproducibilidad


# División de utheca
so_split <- initial_split(utheca, strata = GROUP) # División estratificada
so_train <- training(so_split)
so_test <- testing(so_split)
cv_folds <- vfold_cv(so_train, strata = GROUP) # Pliegues para validación
# cruzada


# Definir métricas
metricas <- metric_set(accuracy, roc_auc, spec, sens, kap, f_meas)


save(so_train, so_test, cv_folds, metricas, file = "models/utheca_splits.RData")
