
library(ArchiData)
library(magrittr)

calc_utci <- function(df, method) {

  if (method == "utci") {

    df %<>%
      mutate(Classification.UTCI = UTCI2classification(UTCI))

  } else if (method == "solar") {
    df %<>%
      mutate(Radiant_temperature = calc_Tmrt(Air_temperature, Solar_radiation, Wind_speed)) %>%
      mutate(UTCI = ArchiData::UTCI(Air_temperature, Radiant_temperature, Wind_speed, Relative_humidity)) %>%
      mutate(Classification.UTCI = UTCI2classification(UTCI))
  } else if (method == "tg") {

    df %<>%
      mutate(Radiant_temperature = ArchiData::MRT(Air_temperature, Globe_temperature, Wind_speed)) %>%
      mutate(UTCI = ArchiData::UTCI(Air_temperature, Radiant_temperature, Wind_speed, Relative_humidity)) %>%
      mutate(Classification.UTCI = UTCI2classification(UTCI))

  }  else {

    df %<>%
      mutate(UTCI = ArchiData::UTCI(Air_temperature, Radiant_temperature, Wind_speed, Relative_humidity)) %>%
      mutate(Classification.UTCI = UTCI2classification(UTCI))

  }
  return(df)
}


