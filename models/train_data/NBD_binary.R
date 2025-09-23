
library(readxl)
library(tidyverse)
library(tidymodels)
library(readxl)
library(themis)
library(kableExtra)
library(naivebayes)
library(discrim)
library(future)

load("models/train_data/splits_binaryX01.RData")

# --------------------------
# NAIVE BAYES con tidymodels
# --------------------------

set.seed(2302)

# Definir hiperparámetros para Naive-Bayes
# (laplace: suavizado, smoothness/adjust: varianza en kernel gaussiano, etc.)
param_nb <- expand_grid(
  smoothness = c(0.5, 1, 2),   # Ajusta varianza (ancho del kernel)
  Laplace = c(0, 1)           # Suavizado de Laplace
)

# Modelo Naive Bayes
model_nb <- naive_Bayes(
  smoothness = tune(),   # ancho kernel
  Laplace = tune()       # suavizado
) %>%
  set_engine("naivebayes") %>%
  set_mode("classification")

# Receta de preprocesamiento (igual que antes)
so_down <- recipe(GROUP ~ ., data = so_train) %>%
  step_novel(all_nominal(), -all_outcomes()) %>%
  step_unknown(all_nominal(), -all_outcomes()) %>%
  step_dummy(all_nominal(), -all_outcomes()) %>%
  step_zv(all_numeric_predictors()) %>%
  step_corr(all_numeric_predictors()) %>%
  step_lincomb(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_smote(all_outcomes())

# Workflow para Naive-Bayes
nb_wf_down <- workflow() %>%
  add_recipe(so_down) %>%
  add_model(model_nb)

# Entrenamiento con validación cruzada
plan(multisession, workers = parallel::detectCores(logical = FALSE))

nb_fit_down <- nb_wf_down %>%
  tune_grid(cv_folds, metrics = metricas, grid = param_nb)

# Mostrar mejores resultados
for (i in c("accuracy", "roc_auc", "spec", "sens", "kap", "f_meas", "bal_accuracy")) {
  print(nb_fit_down %>% show_best(metric = i, n = 3))
}

# Seleccionar mejor modelo
best_nb_spec <- nb_fit_down %>% select_best(metric = "accuracy")

# Finalizar workflow con mejor modelo
final_nb_wf <- nb_wf_down %>%
  finalize_workflow(best_nb_spec)

# Evaluación en conjunto de test
final_nb_fit <- final_nb_wf %>%
  last_fit(so_split, metrics = metricas)

table(final_nb_fit$.predictions[[1]]$.pred_class,final_nb_fit$.predictions[[1]]$GROUP)

# Métricas finales
(met_nb <- collect_metrics(final_nb_fit))
tabla_nb_spec <- matrix(round(met_nb$.estimate, 4))
tabla_nb_spec <- t(cbind(met_nb$.metric, tabla_nb_spec))
colnames(tabla_nb_spec) <- met_nb$.metric
tabla_nb_spec <- t(tabla_nb_spec[2,])

# Guardar modelo
NB_binary <- final_nb_fit %>% extract_workflow()
# save(NB_binary, file = "models/NB_binary.RData")
