
library(tidymodels)

load("models/XGB_binary.RData")
load("models/XGB_multiclass.RData")

NBD <- readRDS("models/NBD_binary.rds")
NBD_multiclass <- readRDS("models/NBD_multiclass.rds")

predict_function <- function(model, new_data, gender, age) {
  # Make predictions using the model
  if (model == "NBD"){
    new_data <- new_data %>%
      rename(
        tair = Air_temperature,
        rh = Relative_humidity,
        wind_sp = Wind_speed,
        tglobe = Globe_temperature
      )
    predictions <- predict(NBD, new_data, type = "prob")$.pred_Comfort
  }

  if (model == "XGB"){
    new_data <- new_data %>%
      rename(
        tair = Air_temperature,
        rh = Relative_humidity,
        wind_sp = Wind_speed,
        tglobe = Globe_temperature) %>%
      mutate(
        age = age,
        sex = gender
      )
    predictions <- predict(XGB, new_data, type = "prob")$.pred_Comfort
  }

  return(predictions)
}



predict_function_multi <- function(model, new_data, gender, age) {
  # Make predictions using the model
  if (model == "XGB"){
    new_data <- new_data %>%
      rename(
        tair = Air_temperature,
        rh = Relative_humidity,
        wind_sp = Wind_speed,
        tglobe = Globe_temperature) %>%
      mutate(
        age = age,
        sex = gender
      )
    predictions <- predict(XGB_multiclass, new_data)$.pred_class
  }
  # Make predictions using the model
  if (model == "NBD"){
    new_data <- new_data %>%
      rename(
        tair = Air_temperature,
        rh = Relative_humidity,
        wind_sp = Wind_speed,
        tglobe = Globe_temperature
      )
    predictions <- predict(NBD_multiclass, new_data)
    predictions <- predictions %>% mutate(.pred_class = case_when(
          .pred_class == -2 ~ "Very cold",
          .pred_class == -1 ~ "Cold",
          .pred_class ==  0 ~ "Neither cool nor warm",
          .pred_class ==  1 ~ "Warm",
          .pred_class ==  2 ~ "Very hot"
          ))
    predictions <- predictions$.pred_class
  }

  return(predictions)
}
