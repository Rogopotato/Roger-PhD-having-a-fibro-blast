install.packages("survival")
install.packages("survminer")
install.packages("ggfortify")
install.packages("factoextra")
install.packages("aod")

library(plyr)
library(readr)
library(dplyr)
library(caret)
library(survival)
library(survminer)
library(ggplot2)
library(ggfortify)
library(factoextra)
library(aod)

setwd("C:/Users/roger/OneDrive/Desktop/biomarker R stuff")
mydata <- read_csv("biomarker_cox_regression_2.csv")
rownames(mydata) <- mydata[,1]
mydata[,1] <- NULL
attach(mydata)
summary(Time)

#model <- lm(Status~ Gender + Age + BMI + Treatment + pFVC + pDLCO + MMP7 + POSTN + ICAM1 + CHI3L1 + CCL18,
#            data = mydata)
#summary(model)
#wald.test(Sigma = vcov(model), b = coef(model), Terms = 9)

#multivariate
# you need to manually input all the factors you want to include in the analysis. All variables should be in rows.
# Time is survival, Status is 1 for dead and 0 for alive. All data should be numerical e.g. male = 1 female = 0 
model <- coxph(Surv(Time, Status)
               ~ Age + Gender + BMI + Treatment + pFVC + pDLCO + MMP7 + POSTN + ICAM1 + CXCL13 + OPN + SPD + CHI3L1 + CCL18 + CA125,
               method = "breslow")
summary(model)


ggsurvplot(survfit(model, data = mydata), palette = "#2E9FDF")
           
#univariate
coxph <- coxph(Surv(Time, Status)
               ~ MMP7,
               method = "breslow")
summary(coxph)

#scree plot
res.pca <- princomp(mydata, cor = TRUE, scale = TRUE)
fviz_eig(res.pca)
#plot PCA
fviz_pca_ind(res.pca,
             col.ind = "cos2", # Color by the quality of representation
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     # Avoid text overlapping
)

fviz_pca_var(res.pca,
             col.var = "contrib", # Color by contributions to the PC
             gradient.cols = c("#00AFBB", "#E7B800", "#FC4E07"),
             repel = TRUE     # Avoid text overlapping
)

