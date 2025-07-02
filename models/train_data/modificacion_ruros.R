
ruros <- readRDS("models/train_data/ruros.rds")

library(dplyr)

ruros <- readRDS("models/train_data/ruros.rds")

library(dplyr)

ruros <- ruros %>%
  select(age,sex,tair,tglobe,wind_sp,rh,heat) %>%
  mutate(sex = case_when(
    sex == 1 ~ "Male",
    sex == 2 ~ "Female"
  )) %>%
  mutate(heat = case_when(
    heat == -2 ~ "Very cold",
    heat == -1 ~ "Cold",
    heat ==  0 ~ "Neither cool nor warm",
    heat ==  1 ~ "Warm",
    heat ==  2 ~ "Very hot"
  ))
ruros <- ruros %>%
mutate(across(where(~is.character(.)), as.factor))

saveRDS(ruros, "models/train_data/Ruros_train.rds")
