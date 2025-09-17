library(readxl)
library(tidyverse)
library(tidymodels)
library(readxl)
library(themis)
library(kableExtra)
library(ranger)


version = "X01" %>% as.character()

dict_existe_split_manual = list(
  "4" = TRUE,
  "X01" = FALSE,
  "X02" = TRUE,
  "X03" = TRUE,
  "X04" = TRUE,
  "X05" = TRUE
)

