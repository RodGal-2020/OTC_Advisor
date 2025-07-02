
library(readxl)
library(tidyverse)
library(tidymodels)
library(readxl)
library(themis)
library(kableExtra)
library(ranger)
library(xgboost)
library(future)

load("models/train_data/splits_multiclass.RData")

### RANDOM FOREST
set.seed(2302)
# Definir hiperparámetros a considerar para el ajuste del modelo
param <- expand_grid(
  trees = c(100, 150, 200),         # Menor número para evitar sobreajuste inicial
  min_n = c(3, 5, 10),              # Controla el mínimo de datos por hoja
  tree_depth = c(3, 5),             # Reduzco a 2 valores razonables
  learn_rate = c(0.01, 0.05, 0.1),  # Valores conservadores para no aprender demasiado rápido
  loss_reduction = c(0, 1),         # Gamma, control de regularización
  sample_size = c(0.7, 0.9, 1.0)    # Submuestreo, puede ayudar contra overfitting
)


# Modelo de XGB
model_xgb <- boost_tree(tree_depth = tune(),
                        learn_rate = tune(),
                        loss_reduction = tune(),
                        min_n = tune(),
                        sample_size = tune(),
                        trees = tune()) %>%
  set_engine("xgboost") %>% # Usar el motor 'xgboost'
  set_mode("classification") # Establecer el modo de clasificación

# Preparar la receta de preprocesamiento con downsampling
so_down <- recipe(heat ~ ., data = so_train) %>%
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


xgb_wf_down <- workflow() %>%
  add_recipe(so_down) %>%
  add_model(model_xgb) # Añadir modelo al flujo de trabajo

plan(multisession, workers = parallel::detectCores(logical = FALSE))

xgb_fit_down <- xgb_wf_down %>%
  tune_grid(cv_folds, metrics = metricas, grid = param) # Ajustar
# hiperparámetros usando validación cruzada

for (i in c("accuracy", "roc_auc", "spec", "sens", "kap", "f_meas", "bal_accuracy")) {
  print(xgb_fit_down %>% show_best(metric = i, n = 3))
}


# Seleccionar el mejor modelo basado en especificidad
best_tree_spec <- xgb_fit_down %>% select_best(metric = "bal_accuracy")

# Finalizar el flujo de trabajo con el mejor modelo
final_wf <-
  xgb_wf_down %>%
  finalize_workflow(best_tree_spec)

# Evaluar el modelo en el conjunto de prueba
final_fit <-
  final_wf %>%
  last_fit(so_split, metrics = metricas)

# Matriz de confusion
table(final_fit$.predictions[[1]]$.pred_class,final_fit$.predictions[[1]]$heat)

# Recoger métricas del ajuste final
met_xgb <- collect_metrics(final_fit)
tabla_xgb_spec <- matrix(round(met_xgb$.estimate, 4))
tabla_xgb_spec <- t(cbind(met_xgb$.metric, tabla_xgb_spec))
colnames(tabla_xgb_spec) <- met_xgb$.metric
tabla_xgb_spec <- t(tabla_xgb_spec[2,])


## save model
XGB_multiclass <- final_fit %>% extract_workflow()
save(XGB_multiclass, file = "models/XGB_multiclass.RData")
