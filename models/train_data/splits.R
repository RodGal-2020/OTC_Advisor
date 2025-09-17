
library(readxl)
library(tidyverse)
library(tidymodels)
library(readxl)
library(themis)
library(kableExtra)
library(ranger)

# Cargar y preparar los datos
ruros <- readRDS("models/train_data/Ruros_Utheca_all.rds")
ruros <- ruros %>%
  select("Date","Time","tair","rh","tglobe","wind_sp","mrt","sex","heat","age","clo","met_rate","Time_per","sun_shade","Season")



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
data <- data %>% drop_na() # Eliminar filas con NA y heat = 3 (pocos casos))

train_idx <- which(!year(data$Date) %in% c(2024,2025))

test_idx  <- which(year(data$Date) %in% c(2024,2025))


data <- data %>%
  select("tair","rh","wind_sp","mrt","sex","heat","age","clo","met_rate","Season")

set.seed(2302) # Fijar semilla para reproducibilidad

# # División de ruros
# so_split <- initial_split(data, strata = heat) # División estratificada
# so_train <- training(so_split)
# so_test <- testing(so_split)
# cv_folds <- vfold_cv(so_train, strata = heat) # Pliegues para validación
# cruzada

# indices para train y test


# Crear split manual
so_split <- make_splits(list(analysis = train_idx, assessment = test_idx), data = data)

# Ahora ya puedes usar:
so_train <- training(so_split)
so_test  <- testing(so_split)
cv_folds <- vfold_cv(so_train, strata = heat)



# Definir métricas
metricas <- metric_set(accuracy, roc_auc, spec, sens, kap, f_meas, bal_accuracy)


save(so_split, so_train, so_test, cv_folds, metricas, file = "models/train_data/splits_multiclass4.RData")

# Crar variable Comfort y Discomfort para equilibrar las clases
data <- data %>%
  mutate(GROUP = case_when(
    heat == 0 ~ "Comfort",
    heat != 0 ~ "Discomfort"
  )) %>%
  mutate(GROUP = factor(GROUP, levels = c("Comfort", "Discomfort"))) %>%
  select(-heat) # Eliminar la columna heat

# División de ruros
# so_split <- initial_split(data, strata = GROUP) # División estratificada
# so_train <- training(so_split)
# so_test <- testing(so_split)
# cv_folds <- vfold_cv(so_train, strata = GROUP) # Pliegues para validación
# cruzada
#
so_split <- make_splits(list(analysis = train_idx, assessment = test_idx), data = data)

# Ahora ya puedes usar:
so_train <- training(so_split)
so_test  <- testing(so_split)
cv_folds <- vfold_cv(so_train, strata = GROUP)

save(so_split, so_train, so_test, cv_folds, metricas, file = "models/train_data/splits_binary4.RData")
