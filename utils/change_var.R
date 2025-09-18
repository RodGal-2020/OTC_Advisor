library(readxl)
library(dplyr)
library(lubridate)


change_var <- function(new_data) {
    new_data <- new_data %>%
      mutate(
        age = case_when(
          age == "< 12" ~ 1,
          age == "13 - 17" ~ 2,
          age == "18 - 24" ~ 3,
          age == "25 - 34" ~ 4,
          age == "35 - 44" ~ 5,
          age == "45 - 54" ~ 6,
          age == "55 - 64" ~ 7,
          age == "> 65"~ 8
        ),
        sex = case_when(
          sex == "Male" ~ 1,
          sex == "Female" ~ 2
        ),
        met_rate = case_when(
          met_rate == "Seated relaxed" ~ 58,
          met_rate == "Standing" ~ 80,
          met_rate == "Walking" ~ 150,
          met_rate == "Bicycling" ~ 232,
          met_rate == "Running" ~ 464,
        ),
        clo = case_when(
          clo == "Light short-sleeved T-shirt and shorts" ~ 0.3,
          clo == "Long-sleeved T-shirt or polo with light trousers" ~ 0.5,
          clo == "Long-sleeved shirt + lightweight long trousers" ~ 0.7,
          clo == "Office wear: shirt, long trousers, light jacket" ~ 0.9,
          clo == "Full business suit (shirt, jacket, trousers)" ~ 1,
          clo == "Warmer clothing" ~ 1.2,
        ),
        Season = case_when(
          Season == "Summer" ~ 1,
          Season == "Autumn" ~ 2,
          Season == "Winter" ~ 3,
          Season == "Spring" ~ 4,
        )
      ) %>%
      mutate(across(c(sex,age,Season), as.factor))
}














