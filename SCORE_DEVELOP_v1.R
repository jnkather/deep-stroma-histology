# JN Kather, NCT Heidelberg / RWTH Aachen, 2017-2018
# see separate LICENSE 
#
# This R script is associated with the following project
# "A deep learning based stroma score is an independent prognostic 
# factor in colorectal cancer"
# Please refer to the article and the supplemntary material for a
# detailed description of the procedures. This is experimental software
# and should be used with caution.
# 
# this script is used to develop the deep stroma score
#
rm(list=ls(all=TRUE)) # clear all
cat("\014")           # clc
library(survminer)    # load required libraries
library(survival)
library(ggfortify)
library(OptimalCutpoints)
library(openxlsx)
dosave <- T
dir.create("./kaplan_out"); # create output dir
# locate and load input data
setwd("[insert path here]")

for (myTableName in c("TCGA_FULL","DACHS_FULL_OS","DACHS_FULL_CRCS")) { # "DACHS_FULL_OS" DACHS_FULL_CRCS TCGA_FULL
  for (mySubset in c("ALL")) {
  
if ((myTableName =="TCGA_FULL")) {
  myTable = read.xlsx("TCGA_MEASUREMENTS.xlsx")
myTable$OS_event <- myTable$vital_status
myTable$days_to_event <- myTable$days_to_event/365.25 # days to years
myTable$decades_to_birth <- myTable$years_to_birth/10
} else if ((myTableName =="DACHS_OS") || (myTableName =="DACHS_CRCS")) {
  myTable = read.xlsx( "DACHS_MEASUREMENTS.xlsx") 
  columnShift <- 0 # no need to shift columns because ADI BACK etc are columns 2 3 etc
  if (myTableName == "DACHS_OS") {
  myTable$OS_event <- myTable$death_event_35fu 
  } else if (myTableName == "DACHS_CRCS") {
    myTable$OS_event <- myTable$crc_death_35fu 
  }
  myTable$days_to_event <- myTable$fudays_35fu/365.25 # days to years
  myTable$decades_to_birth <- myTable$indexage/10
  myTable$gender <- myTable$sex
  myTable$cleanstage <- myTable$crcstage
}

    if (mySubset == "STAGE1") {
      myTable = subset(myTable,(cleanstage==1))
    } else if (mySubset == "STAGE2") {
      myTable = subset(myTable,(cleanstage==2))
    } else if (mySubset == "STAGE3") {
      myTable = subset(myTable,(cleanstage==3))
    } else if (mySubset == "STAGE4") {
      myTable = subset(myTable,(cleanstage==4))
    } 

my.surv <- Surv(myTable$days_to_event, myTable$OS_event)

allNames = names(myTable) # re-query all names
cutoffVector = NaN # preallocate
weightVector = NaN # preallocate
pVector = NaN # preallocate
index.components = c(2:10)

# DRAW KAPLAN MEIER FOR COMPONENTS
cutcount = 0 # initialize counter for cutoffs
for (i in c(index.components)) # index.components
{
  print(paste("STARTING",names(myTable)[i]))
  cutcount = cutcount+1 # increment counter for cutoffs
  currentMeasurement = myTable[,i]
  optcut <- optimal.cutpoints(X = allNames[i], status = "OS_event", tag.healthy = 0,
                              methods = c("Youden"),  data = myTable, pop.prev = NULL, 
                              control = control.cutpoints(), ci.fit = TRUE, conf.level = 0.95, trace = FALSE)
  mycut <- optcut$Youden$Global$optimal.cutoff[1]$cutoff
  
  
  # UNIVARIATE CONTINUOUS COX PH MODEL
  mycox <- coxph(my.surv ~ (get(allNames[i])), data = myTable) 
  lastHR <- round(summary(mycox)$coef[2],digits=2)
  lastP <- round(summary(mycox)$coefficients[5],digits=3) # extract the last walden p value from cox model
  print(summary(mycox))
  
  # MULTIVARIATE CONTINUOUS COX PH MODEL
  mycoxMult <- coxph(my.surv ~ (get(allNames[i])) + (cleanstage) + factor(gender) + decades_to_birth, data = myTable) # compute MULTI, THRESH cox hazard model
  currentHRmulti = round(summary(mycoxMult)$coef[5]  ,digits=2)
  currentPmulti = round(summary(mycoxMult)$coef[17],digits=4)
  print(summary(mycoxMult))
  
  print(paste(allNames[i]," exp(coef): ",round(summary(mycox)$conf.int[1],digits=3)," low CI: ",
              round(summary(mycox)$conf.int[3],digits=3), " high CI: ", round(summary(mycox)$conf.int[4],digits=3)," p = ",lastP))
  #print(summary(optcut))
  
  print(paste("Youden cutoff:",mycut))

  if (i %in% index.components) {
  cutoffVector = c(cutoffVector,round(mycut,digits=5))
  weightVector = c(weightVector,round(summary(mycox)$conf.int[1],digits=3)) # weight is HR
  pVector = c(pVector,lastP)
  }
  
  if (length(mycut)>1) { # if more than 1 optimal cut points, choose the one close to the median
    currentCut <- mycut[which.min(mycut - median(na.omit(currentMeasurement)))]
    currLevels = (currentMeasurement>=currentCut)
  } 
  else {  
    currentCut = mycut
    currLevels = (currentMeasurement>=currentCut)
    }
  my.fit <- survfit(my.surv ~ currLevels) 
 
  if (dim(my.fit)>1) {
    ggsurv <- ggsurvplot(
      my.fit, data = myTable, size = 1.5, risk.table = TRUE,     
      pval = TRUE,  conf.int = FALSE, # palette = c("#1B9E77", "#D95F02"),
      xlab = "t (years)",   break.time.by = 2,     # break X axis in time intervals by 500.
      ggtheme = theme_light(), ncensor.plot = FALSE,     
      conf.int.style = "step" #, legend.labs = c("low","high")
    )
    ggsurv$plot <- ggsurv$plot + labs(title    = paste(allNames[i],"cut:",round(currentCut,digits=4),"\n","uni cox continuous HR:",
                                                       lastHR,"uni cox continuous p:",lastP,"\n","multi cox continuous HR:",currentHRmulti,
                                                       "multi cox continuous p:",currentPmulti,sep=" "))
    
     ggsurv <- ggpar(
      ggsurv, font.title = c(12, "bold", "black"),         
      font.x = c(14, "plain", "black"), font.y = c(14, "plain", "black"),          
      font.xtickslab = c(14, "plain", "black"),  legend = "top",      
      font.ytickslab = c(14, "plain", "black"))
    survp <- ggsurv
  if ( dosave ) {
  #ggsave(paste("./kaplan_out/",myTableName,allNames[i],mySubset,".pdf",sep="_"), print(survp))
    ggsave(paste("./kaplan_out/",myTableName,allNames[i],mySubset,".png",sep="_"), print(survp))
  }
  } else { print("NO DRAW")}
}
  }
}