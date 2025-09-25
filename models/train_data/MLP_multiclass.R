source(here::here("models/config.R"))
library(nnet)
library(future)

load("models/train_data/splits_multiclassX01.RData")

### MULTI-LAYER PERCEPTRON (MLP)
set.seed(2302)
# Definir hiperparámetros a considerar para el ajuste del modelo
param <- expand_grid(
  hidden_units = c(3, 5, 10),       # Número de neuronas en la capa oculta
  penalty = c(1e-4, 1e-2, 0.1),     # Regularización: weight decay
  epochs = c(100, 200, 500)         # Número de épocas de entrenamiento
)

# Modelo MLP
model_mlp <- mlp(
  hidden_units = tune(),
  penalty = tune(),
  epochs = tune()
) %>%
  set_engine("nnet") %>%              # Usar el motor 'nnet'
  set_mode("classification")          # Modo clasificación multicategoría

# Preparar la receta de preprocesamiento con downsampling
so_down <- recipe(heat ~ ., data = so_train) %>%
  step_novel(all_nominal(), -all_outcomes()) %>%
  step_unknown(all_nominal(), -all_outcomes()) %>%
  step_dummy(all_nominal(), -all_outcomes()) %>%
  step_zv(all_numeric_predictors()) %>%
  step_corr(all_numeric_predictors()) %>%
  step_lincomb(all_numeric_predictors()) %>%
  step_normalize(all_numeric_predictors()) %>%
  step_smote(all_outcomes())

# Crear flujo de trabajo para MLP con downsampling
mlp_wf_down <- workflow() %>%
  add_recipe(so_down) %>%
  add_model(model_mlp)

plan(multisession, workers = parallel::detectCores(logical = FALSE))

mlp_fit_down <- mlp_wf_down %>%
  tune_grid(cv_folds, metrics = metricas, grid = param)

for (i in c("accuracy", "roc_auc", "spec", "sens", "kap", "f_meas", "bal_accuracy")) {
  cat("------------------------------\nMetric: ", i, "\n")
  cat("Best results:\n")
  print(mlp_fit_down %>% show_best(metric = i, n = 3))
}

# Seleccionar el mejor modelo basado en especificidad
best_mlp_spec <- mlp_fit_down %>% select_best(metric = "bal_accuracy")

# Finalizar el flujo de trabajo con el mejor modelo
final_wf <-
  mlp_wf_down %>%
  finalize_workflow(best_mlp_spec)

# Evaluar el modelo en el conjunto de prueba
final_fit <-
  final_wf %>%
  last_fit(so_split, metrics = metricas)

# Matriz de confusion
table(final_fit$.predictions[[1]]$.pred_class, final_fit$.predictions[[1]]$heat)

# Recoger métricas del ajuste final
(met_mlp <- collect_metrics(final_fit))
tabla_mlp_spec <- matrix(round(met_mlp$.estimate, 4))
tabla_mlp_spec <- t(cbind(met_mlp$.metric, tabla_mlp_spec))
colnames(tabla_mlp_spec) <- met_mlp$.metric
tabla_mlp_spec <- t(tabla_mlp_spec[2,])

## save model
MLP_multiclass <- final_fit %>% extract_workflow()
# save(MLP_multiclass, file = "models/MLP_multiclass.RData")
