source(here::here("models/config.R"))

# Cargar y preparar los datos
ruros <- readRDS("models/train_data/Ruros_Utheca_mediterranean.rds")

# belahorizonte <- readRDS("models/train_data/BH_en_sombra_modified.rds")
# belahorizonte <- belahorizonte %>%
#   select("Date","Time","tair","rh","tglobe","wind_speed","mrt","sex","heat","age","clo","met_rate","Time_per","sun_shade","Season") %>%
#   rename(wind_sp = wind_speed)

ruros <- ruros %>%
  mutate(across(c(sex,heat,age,Time_per,sun_shade,Season), as.factor))
# belahorizonte <- belahorizonte %>%
#   mutate(across(c(sex,heat,age,Time_per,sun_shade,Season), as.factor))
#
# data <- bind_rows(ruros, belahorizonte) # Unir ambos datasets
data <- ruros
data <- data %>% drop_na() # Eliminar filas con NA

# switch(version,
#        "4" = {
#          train_idx <- which(!year(data$Date) %in% c(2024,2025))
#          test_idx  <- which(year(data$Date) %in% c(2024,2025))
#         }, # Versión 4
#        "X01" = {
#          train_idx <- which(!year(data$Date) %in% c(2024,2025))
#          test_idx  <- which(year(data$Date) %in% c(2024,2025))
#        }, # Versión 4X01
#        stop("Versión no válida, modifica el switch de splits.R")
# )

# Selección de variables
data <- data %>%
  select("tair","rh","wind_sp","mrt","sex","heat","age","clo","met_rate","Season")

set.seed(2302) # Fijar semilla para reproducibilidad

########################
# Clasificación Multiclase
########################

# Crear split manual
# if (dict_existe_split_manual %>% magrittr::extract2(version)) {
#   so_split <- make_splits(list(analysis = train_idx, assessment = test_idx), data = data)
# } else {
#   so_split <- initial_split(data, strata = heat) # División estratificada
#   train_idx <- so_split$in_id
#   test_idx  <- setdiff(1:nrow(data), train_idx)
# }

so_split <- initial_split(data, strata = heat) # División estratificada
# Ahora ya puedes usar:
so_train <- training(so_split)
so_test  <- testing(so_split)
cv_folds <- vfold_cv(so_train, strata = heat)

# Definir métricas
metricas <- metric_set(accuracy, roc_auc, spec, sens, kap, f_meas, bal_accuracy)


save(so_split, so_train, so_test, cv_folds, metricas, file = paste0("models/train_data/splits_multiclass",version, ".RData"))

########################
# Clasificación binaria
########################
# Crar variable Comfort y Discomfort para equilibrar las clases
data <- data %>%
  mutate(GROUP = case_when(
    heat == 0 ~ "Comfort",
    heat != 0 ~ "Discomfort"
  )) %>%
  mutate(GROUP = factor(GROUP, levels = c("Comfort", "Discomfort"))) %>%
  select(-heat) # Eliminar la columna heat

# Crear split manual o no, de nuevo
# if (dict_existe_split_manual %>% magrittr::extract2(version)) {
#   so_split <- make_splits(list(analysis = train_idx, assessment = test_idx), data = data)
# } else {
#   so_split <- initial_split(data, strata = heat) # División estratificada
#   train_idx <- so_split$in_id
#   test_idx  <- setdiff(1:nrow(data), train_idx)
# }

so_split <- initial_split(data, strata = GROUP)
# Ahora ya puedes usar:
so_train <- training(so_split)
so_test  <- testing(so_split)
cv_folds <- vfold_cv(so_train, strata = GROUP)

save(so_split, so_train, so_test, cv_folds, metricas, file = paste0("models/train_data/splits_binary",version, ".RData"))
