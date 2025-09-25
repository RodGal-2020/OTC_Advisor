
library(tidymodels)

source("utils/change_var.R")

load("models/XGB_binary.RData")
load("models/XGB_multiclass.RData")

load("models/NB_binary.RData")
load("models/NB_multiclass.RData")

load("models/MLP_binary.RData")
load("models/MLP_multiclass.RData")

predict_function <- function(model, new_data, gender, age, clo, met_rate, season) {
  # Make predictions using the model
  new_data <- new_data %>%
    rename(
      tair = Air_temperature,
      rh = Relative_humidity,
      wind_sp = Wind_speed,
      mrt = Radiant_temperature) %>%
    mutate(
      age = age,
      sex = gender,
      clo = clo,
      met_rate = met_rate,
      Season = season
    )
  new_data <- change_var(new_data)

  predictions = switch(model,
    "MLP" = predict(MLP_binary, new_data, type = "prob")$.pred_Comfort,
    "NBD" = predict(NB_binary, new_data, type = "prob")$.pred_Comfort,
    "XGB" = predict(XGB_binary, new_data, type = "prob")$.pred_Comfort
  )

  return(predictions)
}



predict_function_multi <- function(model, new_data, gender, age, clo, met_rate, season) {
  # Make predictions using the model
  new_data <- new_data %>%
    rename(
      tair = Air_temperature,
      rh = Relative_humidity,
      wind_sp = Wind_speed,
      mrt = Radiant_temperature) %>%
    mutate(
      age = age,
      sex = gender,
      clo = clo,
      met_rate = met_rate,
      Season = season
    )
  new_data <- change_var(new_data)


  predictions = switch(model,
     "MLP" = predict(MLP_multiclass, new_data, type = "prob")$.pred_Comfort,
     "NBD" = predict(NB_multiclass, new_data, type = "prob")$.pred_Comfort,
     "XGB" = predict(XGB_multiclass, new_data, type = "prob")$.pred_Comfort
  )

  predictions <- tibble(predictions = predictions) %>%
    mutate(predictions = as.numeric(as.character(predictions))) %>%
    mutate(predictions = case_when(
      predictions == -2 ~ "Very cold",
      predictions == -1 ~ "Cold",
      predictions ==  0 ~ "Neither cool nor warm",
      predictions ==  1 ~ "Warm",
      predictions ==  2 ~ "Very hot"
      ))



  return(as.character(predictions$predictions))
}
