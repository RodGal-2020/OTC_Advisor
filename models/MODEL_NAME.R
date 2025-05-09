# We want to define here a logistic regression model for the dataset
library(magrittr)
library(tidymodels)

# Load the dataset
Data <- read_xlsx(here::here("templates/OTC_data.xlsx"))
# Colnames:
# Longitude Latitude Air_temperature Relative_humidity Wind_speed Solar_radiation

# Clean the data
Data %<>% mutate(Class = as.factor(Class))

# Create the logistic regression model
MODEL_NAME <- multinom_reg() %>%
  set_engine("nnet") %>%
  fit(
    Class ~ Air_temperature + Relative_humidity + Wind_speed + Solar_radiation,
    data = Data
  )

# MODEL_NAME %>% predict(Data)

# Save MODEL_NAME as RData
save(MODEL_NAME, file = here::here("models", "MODEL_NAME.RData"))
