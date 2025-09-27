#This script is for performing a LASSO regression and testing the fit of the model.
#Designed to predicted a medical outcome from clinical and biological variables.
#Outputs a predicted value for a response variable (i.e. mortality status, mortality time, max speed etc.) and an associated r-square.
#Outputs a plot that displays the fit of the models' predicted values vs actual values.
#Original author:???
#Updated by: Alistair Nash
#Updated by: Roger Li 15/06/2023

library(plyr)
library(readr)
library(dplyr)
library(caret)
library(ggplot2)
library(repr)
library(glmnet)
library(mice)
library(aod)
library(tidyverse)

#enter your data as a csv
#y is response variable, the variable you are trying to predict with the model.
#x is a data frame of the variables from which you are trying to create the model.
setwd("C:/Users/roger/OneDrive/Desktop/biomarker R stuff")
data <- read_csv("biomarker_cox_regression_2.csv")
y <- data[,3] #select which column will be the outcome to be modelled/predicted. In this case it is mortality status a 0 or 1.
x <- data.frame(data[c('Gender', 'BMI', 'Age', 'pFVC', 'pDLCO', 'MMP7', 'POSTN', 'ICAM1', 'CXCL13', 'OPN', 'SPD', 'CHI3L1', 'CCL18', 'CA125')]) #select the variables you want to model. You fiddle with this selection later.

print(x)
print(y)


#impute any missing data with makeX or mice as glmnet cannot handle NA values. 
#Imputation replaces NA based on the 'average' of the rest of the data. 
#impute if you have a smaller sample size or think excluding NA samples may bias your results.
#skip imputation if you have plenty of data, just make sure to remove NA values.

#makeX does 'one-hot' encoding to make your dataframe NAs processable.
#one-hot is some sort of machine learning algorithm to replace NAs with data usable for glmnet.
#x_imp = makeX(x, na.impute = TRUE)

#Multivariate imputation by chained equations (mice).
#mice uses various imputation methods (regressions in a regression!). More flexibility than makeX.
#try different imputation methods such as "pmm", "cart", "lasso.norm" etc.
#documentation on different methods at https://www.rdocumentation.org/packages/mice/versions/3.15.0/topics/mice
md.pattern(x)
x_imp = complete(mice(x, method = "cart"))
x_imp

#scale your numeric data. In this case gender, BMI and age have not been included in the scaling process.
x_scale <- scale(x_imp[c(4,5,6,7,8,9,10,11,12,13,14)])
#for clinical parameters only
#x_scale <- x_imp[c(1,2,3,4,5)]
x_scale
#combine your non-scaled and scaled data into one dataframe
x_scale_imp <- cbind.data.frame(x_imp[c(1,2,3)], x_scale)
x_scale_imp

#This returns the dataframe as a matrix as glmnet can only accept matrixes.
x_matrix = as.matrix.data.frame(x_scale_imp)
y_matrix = as.matrix.data.frame(y)

x_matrix

model <- cv.glmnet(x_matrix, y_matrix, alpha = 1)

#select best lambda for LASSO  
best_lambda <- model$lambda.min
   best_lambda
   plot(model)

#use the best lamda value to perform your LASSO
best_model <- glmnet(x_matrix, y_matrix, alpha = 1, lambda = best_lambda)
   coef(best_model)
   #best_model_output <- as.data.frame(best_model)
   #write.csv(best_model_output, "C:/Users/roger/OneDrive/Desktop/biomarkermodel/model_progression_clinical_only.csv", row.names=TRUE)
      
#produces the predicted values (y) from your model (x).   
   y_predicted <- predict(best_model, s = best_lambda, newx = x_matrix)
   print(y_predicted)
   
   #find SST and SSE
   sst <- sum((y_matrix - mean(y_matrix))^2)
   sse <- sum((y_predicted - y_matrix)^2)
   
   #find the R-Squared
   #close to 1 is a better fit.
   rsq <- 1 - sse/sst
   rsq

  #check your predicted response values. 
  y_predicted
  
  #makes a data frame for ggplot
  lasso_plot <- data.frame(y_predicted)
  
  #plot your graph. Currently is a scatter plot with no axes ticks or scale and no background or grid.
  ggplot(lasso_plot, aes(x = y_matrix, y = y_predicted)) +
    geom_point(shape = 21, fill = "black", color = "black", size = 0.8) +
    labs(x = "Actual Status", y = "Predicted Status") +
    ylim(-0.1, 1) +
    xlim(-0.5, 1.5) +
    theme(axis.line = element_line(colour = "black"),
          axis.text = element_blank(),
          axis.ticks = element_blank(),
          panel.background = element_blank(),
          panel.grid = element_blank(),
          axis.title.x = element_text(margin = margin(t = 20)),
          axis.title.y = element_text(margin = margin(r = 35)))
  
  write.csv(y_predicted, "C:/Users/roger/OneDrive/Desktop/predicted_progression_biomarker_only.csv", row.names=TRUE)
   
  ggplot(lasso_plot, aes(x = y_matrix, y = y_predicted)) + 
    geom_point(shape = 21, fill = "black", color = "black", size = 1) + 
    labs(x = "Actual Status", y = "Predicted Status") +
    ylim(-0.1,1) + 
    xlim(-0.5, 1.5) +
    theme(axis.line = element_line(colour = "black"),
          axis.text.x = element_blank(),
          axis.ticks.x = element_blank(),
          axis.text.y = element_blank(),
          axis.ticks.y = element_blank(),
          panel.background = element_blank())
  

   