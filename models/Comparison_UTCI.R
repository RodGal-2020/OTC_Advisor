
library(ArchiData)
source(here::here("models/config.R"))

# Cargar y preparar los datos
ruros <- readRDS("models/train_data/Ruros_Utheca_mediterranean.rds")

ruros <- ruros %>%
  mutate(
    UTCI = UTCI(ta = tair, vel = wind_sp ,tr = mrt, rh = rh)
  ) %>%
  mutate(
    Classification.UTCI = UTCI2classification(UTCI)
  )%>%
  mutate(GROUP = case_when(
    heat == 0 ~ "Comfort",
    heat != 0 ~ "Discomfort"
  )) %>%
  mutate(GROUP = factor(GROUP, levels = c("Comfort", "Discomfort"))) %>%
  mutate(GROUP_UTCI = case_when(
    Classification.UTCI == "No thermal Stress" ~ "Comfort",
    Classification.UTCI != "No thermal Stress" ~ "Discomfort"
  ))%>%
  mutate(GROUP_UTCI = factor(GROUP_UTCI, levels = c("Comfort", "Discomfort")))

mat_confusion <- ruros %>% conf_mat(truth = GROUP, estimate = GROUP_UTCI) %$%
  table

TP <- mat_confusion["Discomfort", "Discomfort"]
FN <- mat_confusion["Discomfort", "Comfort"]
FP <- mat_confusion["Comfort", "Discomfort"]
TN <- mat_confusion["Comfort", "Comfort"]

# Métricas
Recall <- TP / (TP + FN)                  # Sensibilidad
Specificity <- TN / (TN + FP)             # Especificidad
BACC <- (Recall + Specificity) / 2        # Balanced Accuracy

Recall
Specificity
BACC




ruros <- ruros %>% mutate(
  Classification.UTCI_adapted = case_when(
    Classification.UTCI == "Extreme Cold Stress" ~ "Very cold",
    Classification.UTCI == "Very Strong Cold Stress" ~ "Very cold",
    Classification.UTCI == "Strong Cold Stress"  ~ "Very cold",
    Classification.UTCI == "Moderate Cold Stress" ~ "Cold",
    Classification.UTCI == "Slight Cold Stress" ~ "Cold",
    Classification.UTCI == "No thermal Stress" ~ "Neither cold nor warm",
    Classification.UTCI == "Slight Heat Stress" ~ "Warm",
    Classification.UTCI == "Moderate Heat Stress" ~ "Warm",
    Classification.UTCI == "Strong Heat Stress" ~ "Very hot",
    Classification.UTCI == "Very Strong Heat Stress" ~ "Very hot",
    Classification.UTCI == "Extreme Heat Stress" ~ "Very hot"
  ),
  heat_adapted = case_when(
    heat == -2 ~ "Very cold",
    heat == -1 ~ "Cold",
    heat == 0 ~ "Neither cold nor warm",
    heat == 1 ~ "Warm",
    heat == 2 ~ "Very hot"
  )
) %>%
  mutate(
    Classification.UTCI_adapted = factor(Classification.UTCI_adapted, levels = c("Very cold", "Cold", "Neither cold nor warm", "Warm", "Very hot")),
    heat_adapted = factor(heat_adapted, levels = c("Very cold", "Cold", "Neither cold nor warm", "Warm", "Very hot"))
  )

cm <- ruros %>% conf_mat(truth = heat_adapted, estimate = Classification.UTCI_adapted) %$%
  table

multi_metrics <- function(cm) {
  K <- nrow(cm)
  recalls <- specificities <- numeric(K)

  for (i in 1:K) {
    TP <- cm[i, i]
    FN <- sum(cm[i, -i])
    FP <- sum(cm[-i, i])
    TN <- sum(cm) - TP - FN - FP

    recalls[i] <- TP / (TP + FN)
    specificities[i] <- TN / (TN + FP)
  }

  recall_macro <- mean(recalls, na.rm = TRUE)
  specificity_macro <- mean(specificities, na.rm = TRUE)
  bacc <- mean((recalls + specificities) / 2, na.rm = TRUE)

  list(
    Recall_per_class = recalls,
    Specificity_per_class = specificities,
    Recall_macro = recall_macro,
    Specificity_macro = specificity_macro,
    BACC = bacc
  )
}

multi_metrics(cm)


