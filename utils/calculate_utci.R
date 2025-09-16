
library(ArchiData)
library(magrittr)

calc_utci <- function(df) {

  if (all(c("UTCI") %in% names(df))) {

    df %<>%
      mutate(Classification.UTCI = UTCI2classification(UTCI))

  } else if (all(c("Air_temperature", "Solar_radiation", "Wind_speed", "Relative_humidity") %in% names(df))) {
    df %<>%
      mutate(Radiant_temperature = calc_Tmrt(Air_temperature, Solar_radiation, Wind_speed)) %>%
      mutate(UTCI = ArchiData::UTCI(Air_temperature, Radiant_temperature, Wind_speed, Relative_humidity)) %>%
      mutate(Classification.UTCI = UTCI2classification(UTCI))
  } else if (all(c("Air_temperature", "Globe_temperature", "Wind_speed", "Relative_humidity") %in% names(df))) {
    df %<>%
      mutate(Radiant_temperature = ArchiData::MRT(Air_temperature, Globe_temperature, Wind_speed)) %>%
      mutate(UTCI = ArchiData::UTCI(Air_temperature, Radiant_temperature, Wind_speed, Relative_humidity)) %>%
      mutate(Classification.UTCI = UTCI2classification(UTCI))

  }  else if (all(c("Air_temperature", "Radiant_temperature", "Wind_speed", "Relative_humidity") %in% names(df))) {
    df %<>%
      mutate(UTCI = ArchiData::UTCI(Air_temperature, Radiant_temperature, Wind_speed, Relative_humidity)) %>%
      mutate(Classification.UTCI = UTCI2classification(UTCI))
  } else {
    stop("Data frame must contain either UTCI or Air_temperature, Wind_speed, Relative_humidity and either Solar_radiation, Globe_temperature or Radiant_temperature columns.")
  }
  return(df)
}


