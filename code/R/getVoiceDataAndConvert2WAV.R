#!/usr/bin/env Rscript

# Function to get audio files from synapse and convert them to wav
# Get arguments from comman line
args = commandArgs(TRUE)
table = args[1]
inputFileName = args[2]
columnName = args[3]
workingDir = args[4]

# Clear R console screen output
cat("\014")

# Clear R workspace
setwd(paste0(workingDir, 'R/'))
.libPaths('/mnt/mylibs')

# Load libraries
library(synapseClient);
library(plyr);
library(dplyr);

# Login to synapse
synapseLogin(); 

# Get recordIds for download
records = read.csv(inputFileName, stringsAsFactors = F)

# Voice metadata table download
voiceTable = synTableQuery(paste("SELECT * FROM",table))@values
voiceTable$rowId = rownames(voiceTable)
voiceTable = voiceTable %>%
  tidyr::separate(rowId, into = c("SOURCE_ROW_ID","SOURCE_ROW_VERSION"), sep = "_") %>%
  dplyr::mutate(rowId = paste(SOURCE_ROW_ID,SOURCE_ROW_VERSION, sep = "_"),
                SOURCE_ROW_ID = as.integer(SOURCE_ROW_ID),
                SOURCE_ROW_VERSION = as.integer(SOURCE_ROW_VERSION)) %>%
  dplyr::inner_join(records)

nas <- is.na(voiceTable[, columnName])

# Get voice data from synapse table and convert them to wave format
if (sum(!nas) > 0){
  voiceFiles = lapply(voiceTable$rowId[!nas], function(rowids, table, columnName){
    fileName = try({
      # Download voice m4a file
      fileName = synDownloadTableFile(table, rowids, columnName)
      
      # Convert them to wave file
      system(paste('avconv','-y','-i',fileName,'-b 64k',paste0(fileName,'.wav')))
      paste0(fileName,'.wav')
    }, silent = T)
    return(fileName)
  }, table, columnName)
  names(voiceFiles) = voiceTable$rowId[!nas]
  
  fileNames = plyr::ldply(voiceFiles[sapply(voiceFiles, class) != "try-error"],
                          function(x){data.frame(wavFileName = x)},
                          .id = "rowId") %>%
    tidyr::separate(rowId, into = c("SOURCE_ROW_ID","SOURCE_ROW_VERSION"), sep = "_") %>%
    dplyr::mutate(SOURCE_ROW_ID = as.integer(SOURCE_ROW_ID),
                  SOURCE_ROW_VERSION = as.integer(SOURCE_ROW_VERSION)) %>%
    dplyr::left_join(records)
  write.table(fileNames, file = "wavfileNames.txt", sep = '\t', quote = F, row.names = F)
}