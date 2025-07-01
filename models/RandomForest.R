
library(readxl)
library(tidyverse)
library(tidymodels)
library(readxl)
library(themis)
library(kableExtra)
library(ranger)

load("models/utheca_splits.RData")

### RANDOM FOREST
set.seed(2302)
# Definir hiperparámetros a considerar para el ajuste del modelo
param <- expand_grid(trees = seq(150, 300, by = 50), min_n = c(5, 10),
                     mtry = c(2,3))

# Modelo de Random Forest
model_rf <- rand_forest(trees = tune(), min_n = tune(), mtry = tune()) %>%
  set_engine("ranger", importance = 'impurity') %>% # Usar el motor
  # 'ranger' con importancia de impurity
  set_mode("classification") # Establecer el modo de clasificación

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


rf_wf_down <- workflow() %>%
  add_recipe(so_down) %>%
  add_model(model_rf) # Añadir modelo al flujo de trabajo


# Registrar clúster para paralelización
# registerDoParallel(cl) # Usar clúster para procesamiento paralelo
# Ajuste del modelo de Random Forest
# tiempo_down <- system.time({
  rf_fit_down <- rf_wf_down %>%
    tune_grid(cv_folds, metrics = metricas, grid = param) # Ajustar
  # hiperparámetros usando validación cruzada
# })

rf_fit_down %>% show_best(metric = "roc", n = 1)

# Seleccionar el mejor modelo basado en especificidad
best_tree_spec <- rf_fit_down %>% select_best(metric = "kap")
# Finalizar el flujo de trabajo con el mejor modelo
final_wf <-
  rf_wf_down %>%
  finalize_workflow(best_tree_spec)
# Evaluar el modelo en el conjunto de prueba
final_fit <-
  final_wf %>%
  last_fit(so_split, metrics = metricas)
# Recoger métricas del ajuste final
met_rf <- collect_metrics(final_fit)
tabla_rf_spec <- matrix(round(met_rf$.estimate, 4))
tabla_rf_spec <- t(cbind(met_rf$.metric, tabla_rf_spec))
colnames(tabla_rf_spec) <- met_rf$.metric
tabla_rf_spec <- t(tabla_rf_spec[2,])




