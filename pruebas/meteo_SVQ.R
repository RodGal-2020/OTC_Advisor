library(magrittr)
library(dplyr)

# Read data
data_path <- here::here("meteo_seville.xlsx")

data <- readxl::read_excel(data_path)

data
data %>% glimpse
data %>% summary
