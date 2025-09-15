
install.packages("eplusr")
eplusr::install_eplus("latest")
library(eplusr)
library(dplyr)

epw_svq <- read_epw("templates/conjuntos_prueba/SVQ_23-24.epw", encoding = "unknown")

epw_svq$data() -> dat

dat <- dat %>%
  select("datetime","year","month","day","hour","dry_bulb_temperature",
         "relative_humidity","wind_speed","global_horizontal_radiation")

