
library(tidymodels)

load("models/MODEL_NAME.RData")

NBD <- readRDS("models/NBD.rds")

predict_function <- function(model, new_data) {
  # Make predictions using the model
  if (model == "multinom_reg"){
    predictions <- predict(MODEL_NAME, new_data)$.pred_class
  }

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

  return(predictions)
}
