#!/usr/bin/env Rscript

# Function to get record Ids from synapse table 
# Get arguments from comman line
args = commandArgs(TRUE)
VOICE_ID = args[1]
FEATURE_ID = args[2]
FILENAME = args[3]
WORKING_DIR = args[4]

# Clear R console screen output
cat("\014")

# Clear R workspace
setwd(paste0(WORKING_DIR, 'R/'))
.libPaths('/mnt/mylibs')

# Load required libraries
library('synapseClient')
library(tidyr)
synapseLogin()

### Voice metadata table download
VOICE_TBL = synTableQuery(paste("SELECT * FROM",VOICE_ID))@values
VOICE_TBL$rowId = rownames(VOICE_TBL)
VOICE_TBL = VOICE_TBL %>%
  tidyr::separate(rowId, into = c("SOURCE_ROW_ID","SOURCE_ROW_VERSION"), sep = "_") %>%
  dplyr::mutate(SOURCE_ROW_ID = as.integer(SOURCE_ROW_ID),
                SOURCE_ROW_VERSION = as.integer(SOURCE_ROW_VERSION))

### Finished feature table download
FEATURE_TBL = synTableQuery(paste("SELECT * FROM",FEATURE_ID))@values

# Get unfinished records
if (dim(FEATURE_TBL)[1] > 0){
  VOICE_TBL = dplyr::anti_join(
    dplyr::select(VOICE_TBL, SOURCE_ROW_ID, SOURCE_ROW_VERSION, recordId),
    dplyr::select(FEATURE_TBL, SOURCE_ROW_ID, SOURCE_ROW_VERSION, recordId))
} else {
  VOICE_TBL = dplyr::select(VOICE_TBL, SOURCE_ROW_ID, SOURCE_ROW_VERSION, recordId)
}

# Write rowId, rowVersion and recordId to file
write.table(VOICE_TBL, file = paste(WORKING_DIR, 'Matlab', FILENAME, sep = '/'), 
            row.names = F, sep = '\t', quote = F)