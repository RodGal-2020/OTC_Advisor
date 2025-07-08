
# ESTUDIO DESCRIPTIVO

library(tidyverse)
Ruros <- readRDS("~/OTC_Advisor/models/train_data/Ruros.rds")
Ruros %>% summary

library(ArchiData)
Ruros <- Ruros %>%
  mutate(MRT = MRT(T_a = tair,GT = tglobe,V = wind_sp)) %>%
  mutate(UTCI = UTCI(ta = tair, tr = MRT, vel = wind_sp,rh = rh )) %>%
  mutate(UTCI_cat = UTCI2classification(UTCI))%>%
  select(age,sex,tair,tglobe,wind_sp,rh,heat, UTCI) %>%
  mutate(sex = case_when(
    sex == 1 ~ "Male",
    sex == 2 ~ "Female"
  )) %>%
  mutate(heat = as.numeric(as.character(heat)),
         sex = as.factor(sex))


ml <- lm(heat ~ UTCI + sex, data = Ruros)
ml %>% summary


plot(Ruros$heat~Ruros$age)
plot(Ruros$heat~Ruros$sex)

library(ggplot2)


data <- Ruros
ggplot(data, aes(x = UTCI, y = heat, color = age)) +
  geom_jitter(width = 0.2, height = 0.1, alpha = 0.7) +
  labs(x = "UTCI", y = "Heat category", color = "Sex") +
  theme_minimal() +18+
  coord_cartesian(xlim = c(0, 40)) +
  facet_wrap(~ age)



table(Ruros$sex, Ruros$heat)
chisq.test(Ruros$sex, Ruros$heat)
aov(Ruros$heat~Ruros$UTCI) %>% summary
