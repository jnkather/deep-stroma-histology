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
# this script is used to apply the deep stroma score
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

# set the working directory to where this script is
this.dir <- dirname(parent.frame(2)$ofile)
setwd(this.dir)

for (myTableName in c("TCGA_FULL","DACHS_FULL_OS","DACHS_FULL_CRCS")) { # TCGA_FULL ,"DACHS_FULL_OS","DACHS_FULL_CRCS", "DACHS_FULL_RFS"
for (mySubset in c("ALL STAGES" ,"STAGE1","STAGE2","STAGE3","STAGE4")) {
if (myTableName =="TCGA_FULL") {
  myTable = read.xlsx("TCGA_MEASUREMENTS.xlsx")
  myTable$OS_event <- myTable$vital_status
  myTable$days_to_event <- myTable$days_to_event/365.25 # days to years
  myTable$decades_to_birth <- myTable$years_to_birth/10 # years to decades
} else if ((myTableName =="DACHS_FULL_OS") || (myTableName =="DACHS_FULL_CRCS")|| (myTableName =="DACHS_FULL_RFS")) {
  myTable = read.xlsx( "DACHS_MEASUREMENTS.xlsx") 
  if (myTableName == "DACHS_FULL_OS") {
    myTable$OS_event <- myTable$death_event_35fu 
    myTable$days_to_event <- myTable$fudays_35fu/365.25 # days to years
  } else if (myTableName == "DACHS_FULL_CRCS") {
    myTable$OS_event <- myTable$crc_death_35fu 
    myTable$days_to_event <- myTable$fudays_35fu/365.25 # days to years
  } else if (myTableName == "DACHS_FULL_RFS") {
    myTable$OS_event <- myTable$recurr_event_35fu
    myTable$days_to_event <- myTable$fudays_recurr_35fu/365.25 # days to years
  }
  myTable$decades_to_birth <- myTable$indexage/10 # years to decades
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
#           none, ADI,   BACK,    DEB,     LYM,     MUC,     MUS,     NORM,    STR    , TUM 
allCuts = c(NaN,0.00056,0.00227,0.03151,0.00121,0.01123,0.02359,0.06405,0.00122,0.99961) # these are Youden cuts for TCGA_FULL, 25 04 2018
allWeights = c(  NaN, 1.150, 0.015 ,5.967, 1.226, 0.488, 3.761, 0.909 ,1.154, 0.475)     # these are HR for TCGA_FULL, 25 04 2018
medianTrainingSet <- 8.347
myTable$HDScore <- 0 * myTable$ADI # preallocate
scoreIndices = seq(along=(allWeights))[allWeights>=1] # these are the positive HR indices
for (i in na.omit(scoreIndices)) # build up score
{
  myTable$HDScore <- myTable$HDScore + allWeights[i]*as.numeric(myTable[,i]>=allCuts[i])
}
myTable$HDScore = as.numeric(myTable$HDScore>=medianTrainingSet)

allNames = names(myTable) # re-query all names
# GET CORRECT TABLE COL INDICES
if (myTableName == "TCGA_FULL") {
    index.HDscore = c(23,24,dim(myTable)[2])
} else {
    index.HDscore = dim(myTable)[2]
}

# DRAW KAPLAN MEIER FOR COMPONENTS
for (i in c(index.HDscore))
{
  #print(paste("#######","\n","STARTING",names(myTable)[i],mySubset,sep=" "))
  currentMeasurement = myTable[,i] # extract current measurement
  currentCut <- median(currentMeasurement)
  if (currentCut==0) { currentCut <- 0.5 }
  currLevels <- (currentMeasurement >= currentCut)
  my.fit <- survfit(my.surv ~ currLevels)
  
  # UNIVARIATE BINARY COX PH MODEL
  mycox <- coxph(my.surv ~ (get(allNames[i])>=currentCut), data = myTable) 
  lastHR <- round(summary(mycox)$coef[2],digits=2)
  loCIuni <- round(summary(mycox)$conf.int[3],digits=2)
  hiCIuni <-round(summary(mycox)$conf.int[4],digits=2)
  lastP <- round(summary(mycox)$coefficients[5],digits=3) # extract the last walden p value from cox model
  #print(summary(mycox))
  
  # MULTIVARIATE BINARY COX PH MODEL
  mycoxMult <- coxph(my.surv ~ (get(allNames[i])>=currentCut) + (cleanstage) + factor(gender) + decades_to_birth, data = myTable) # compute MULTI, THRESH cox hazard model
  currentHRmulti = round(summary(mycoxMult)$coef[5]  ,digits=2)
  loCImulti= round(summary(mycoxMult)$conf.int[9]  ,digits=2)
  hiCImulti= round(summary(mycoxMult)$conf.int[13]  ,digits=2)
  currentPmulti = round(summary(mycoxMult)$coef[17],digits=4)
  #print(summary(mycoxMult))
  
  print(paste(allNames[i],mySubset,"multi cox bin HR:",currentHRmulti,
              "[",loCImulti,hiCImulti,"]","multi cox bin p:",currentPmulti,sep=" "))
  
  # plot kaplan meier
  ggsurv <- ggsurvplot(
      my.fit, data = myTable, size = 1.5, risk.table = TRUE,     
      pval = TRUE,  conf.int = F, # palette = c("#1B9E77", "#D95F02"),
      xlab = "t (years)",   break.time.by = 2,     # break X axis in time intervals by 500.
      ggtheme = theme_light(), ncensor.plot = FALSE,     
      conf.int.style = "step" #, legend.labs = c("low","high")
    )
    ggsurv$plot <- ggsurv$plot + labs(title    = paste(allNames[i],"cut:",round(currentCut,digits=4),"\n","uni cox thresh HR:",
                                                       lastHR,"[",loCIuni,hiCIuni,"]","uni cox bin p:",lastP,"\n","multi cox bin HR:",currentHRmulti,
                                                       "[",loCImulti,hiCImulti,"]","multi cox bin p:",currentPmulti,sep=" "))
    ggsurv <- ggpar(
      ggsurv, font.title = c(12, "bold", "black"),         
      font.x = c(14, "plain", "black"), font.y = c(14, "plain", "black"),    
      font.xtickslab = c(14, "plain", "black"),  legend = "top",
      font.ytickslab = c(14, "plain", "black"))
    survp <- ggsurv
    if ( dosave ) {
      ggsave(paste("./kaplan_out/",myTableName,allNames[i],mySubset,".pdf",sep="_"), print(survp))
      ggsave(paste("./kaplan_out/",myTableName,allNames[i],mySubset,".png",sep="_"), print(survp))
    }
}

# --- plausibility - plot tumor stage 
my.stage.fit <- survfit(Surv(myTable$days_to_event,myTable$OS_event) ~ cleanstage, data = myTable)
ggsurv <- ggsurvplot(
  my.stage.fit, data = myTable, size = 1.5, risk.table = TRUE,     
  pval = TRUE,  conf.int = F, # palette = c("#1B9E77", "#D95F02"),
  xlab = "t (years)",   break.time.by = 2,     # break X axis in time intervals by 500.
  ggtheme = theme_light(), ncensor.plot = FALSE,     
  conf.int.style = "step" #, legend.labs = c("low","high")
)
ggsurv$plot <- ggsurv$plot + labs(title    = paste(allNames[i],"UICC stage",sep=" "))
ggsurv <- ggpar(
  ggsurv, font.title = c(12, "bold", "black"),         
  font.x = c(14, "plain", "black"), font.y = c(14, "plain", "black"),    
  font.xtickslab = c(14, "plain", "black"),  legend = "top",
  font.ytickslab = c(14, "plain", "black"))
survp <- ggsurv
if ( dosave ) {
  ggsave(paste("./kaplan_out/",myTableName,"stages",".pdf",sep="_"), print(survp))
  ggsave(paste("./kaplan_out/",myTableName,"stages",".png",sep="_"), print(survp))
}
# --- end plot tumor stage

}
}


