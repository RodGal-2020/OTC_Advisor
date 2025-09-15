
library(readxl)
library(tidyverse)
library(tidymodels)
library(readxl)
library(themis)
library(kableExtra)
library(ranger)
library(xgboost)
library(future)

load("models/train_data/splits_binary.RData")

library(sparklyr)

{
# Definir hiperparámetros a considerar para el ajuste del modelo
  param <- expand_grid(
    adjust_deg_free = 1:5, select_features = c(TRUE, FALSE)
  )



#
# library(baguette)
# library(dbarts)
# library(discrim)
# Modelo
model <- gen_additive_mod(adjust_deg_free = tune(), select_features = tune()) |>
  set_engine("mgcv") |>
  set_mode("classification") |>
  translate()

#########################################################
{
set.seed(2302)

# Preparar la receta de preprocesamiento con downsampling
so_down <- recipe(GROUP ~ ., data = so_train) %>%
  step_novel(all_nominal(), -all_outcomes()) %>%
  step_dummy(all_nominal(), -all_outcomes()) %>% # Codificación
  # para variables categóricas
  step_zv(all_numeric_predictors()) %>% # Eliminar predictores numéricos
  # con varianza cero
  step_corr(all_numeric_predictors()) %>% # Eliminar predictores
  # altamente correlacionados
  step_lincomb(all_numeric_predictors()) %>% # Eliminar combinaciones
  # lineales de predictores
  step_normalize(all_numeric_predictors()) %>% # Normalizar predictores
  # numéricos
  step_downsample(all_outcomes()) # Balanceo por downsampling
# Crear flujo de trabajo para Random Forest con downsampling


wf_down <- workflow() %>%
  add_recipe(so_down) %>%
  add_model(model) # Añadir modelo al flujo de trabajo

plan(multisession, workers = parallel::detectCores(logical = FALSE))

fit_down <- wf_down %>%
  tune_grid(cv_folds, metrics = metricas, grid = param) # Ajustar
  # fit_resamples(resamples = cv_folds) # Ajustar el modelo con validación cruzada
# hiperparámetros usando validación cruzada

for (i in c("accuracy", "roc_auc", "spec", "sens", "kap", "f_meas")) {
  print(fit_down %>% show_best(metric = i, n = 3))
}


}
}
