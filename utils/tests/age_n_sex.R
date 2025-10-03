## Multicass
load("models/train_data/splits_multiclassX01.RData")
# Test whether age (factor) affects heat (factor, multiclass)
chisq.test(table(so_train$age, so_train$heat))
# Test whether sex (factor) affects heat (factor, multiclass)
chisq.test(table(so_train$sex, so_train$heat))

## Binary
load(paste0("models/train_data/splits_binary", version, ".RData"))
# Test whether age (factor) affects GROUP (factor, binary)
chisq.test(table(so_train$age, so_train$GROUP))
# Test whether sex (factor) affects heat (factor, multiclass)
chisq.test(table(so_train$sex, so_train$GROUP))
