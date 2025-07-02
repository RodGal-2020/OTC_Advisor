
library(readxl)
library(tidyverse)
library(tidymodels)
library(readxl)
library(themis)
library(kableExtra)
library(ranger)

# Cargar y preparar los datos
ruros <- readRDS("models/train_data/Ruros_train.rds")

ruros <- ruros %>%
  mutate(across(where(~is.character(.)), as.factor)) # Convertir a factor

set.seed(2302) # Fijar semilla para reproducibilidad

# División de ruros
so_split <- initial_split(ruros, strata = heat) # División estratificada
so_train <- training(so_split)
so_test <- testing(so_split)
cv_folds <- vfold_cv(so_train, strata = heat) # Pliegues para validación
# cruzada


# Definir métricas
metricas <- metric_set(accuracy, roc_auc, spec, sens, kap, f_meas, bal_accuracy)


save(so_split, so_train, so_test, cv_folds, metricas, file = "models/train_data/splits_multiclass.RData")

# Crar variable Comfort y Discomfort para equilibrar las clases
ruros <- ruros %>%
  mutate(GROUP = case_when(
    heat == "Neither cool nor warm" ~ "Comfort",
    heat != "Neither cool nor warm" ~ "Discomfort"
  )) %>%
  mutate(GROUP = factor(GROUP, levels = c("Comfort", "Discomfort"))) %>%
  select(-heat) # Eliminar la columna heat

# División de ruros
so_split <- initial_split(ruros, strata = GROUP) # División estratificada
so_train <- training(so_split)
so_test <- testing(so_split)
cv_folds <- vfold_cv(so_train, strata = GROUP) # Pliegues para validación
# cruzada


save(so_split, so_train, so_test, cv_folds, metricas, file = "models/train_data/splits_binary.RData")
