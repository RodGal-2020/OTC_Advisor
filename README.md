# UTHECA OTC Classifier

## Objectives

This projects adresses the problem of classifying Outdoor Thermal Comfort (OTC) into different categories. The goal is to develop a Shiny app using within a machine learning model that can accurately classify OTC based on their features.

## Behavior

The following project can run the Shiny app that allows us to:

- Read a Excel file with OTC data (`Air_temperature`, `Relative_humidity`, `Wind_speed`, `Solar_radiation`...)
- Use our custom trained model, `MODEL_NAME`, to classify OTC
- Provide the classification using other classifiers, such as PET and UTCI
- Use different buttons to modify the custom readings:
  - ¿Is `MRT` available or only `Solar_radiation`?
  - ¿Does the data include geographic coordinates?
- Export the results in a Excel file, including our prediction of the OTC
