biasesResultsDir = "Biases_Output"

biasesFilesVector = list.files(biasesResultsDir)

MAX_BIAS_LENGTH_THRESHOLD = 10

globalBiasesDistrDf <- matrix(0, ncol = 5, nrow = MAX_BIAS_LENGTH_THRESHOLD)
globalBiasesDistrDf <- data.frame(globalBiasesDistrDf)
colnames(globalBiasesDistrDf) <- c("A", "C", "G", "N", "U")
rownames(globalBiasesDistrDf) <- 1:MAX_BIAS_LENGTH_THRESHOLD


for(file in biasesFilesVector){
  
  print(paste("file:",file))
  
  tmpBiasesDistrDf = read.table(paste(biasesResultsDir,"/", file, sep=""), header=TRUE, sep="\t")
  print(tmpBiasesDistrDf)
  print(globalBiasesDistrDf)
  
  globalBiasesDistrDf <- globalBiasesDistrDf + tmpBiasesDistrDf
  
  print(globalBiasesDistrDf)
  cat("------\n\n")
}

colorsVec <- c("green", "blue", "yellow", "grey", "red")

barplot(as.matrix(t(globalBiasesDistrDf)), main="globalBiasesDistrDf", col=colorsVec, legend = colnames(globalBiasesDistrDf))
