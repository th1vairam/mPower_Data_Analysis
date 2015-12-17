#!/usr/bin/env Rscript

# Code to update voice features table in synapse (this assumes a table and schema exists)
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
library(plyr)
library(dplyr)
library(data.table)

synapseLogin()

# Get voice activity metadata from mPower-level1
voiceActivity = synTableQuery(paste('SELECT * FROM', VOICE_ID))
voiceActivity@values$rowId = rownames(voiceActivity@values) 
voiceActivity@values = voiceActivity@values %>%
  tidyr::separate(rowId, into = c("SOURCE_ROW_ID","SOURCE_ROW_VERSION"), sep = "_") %>%
  dplyr::mutate(SOURCE_ROW_ID = as.integer(SOURCE_ROW_ID),
                SOURCE_ROW_VERSION = as.integer(SOURCE_ROW_VERSION))

# Get completed feature-set
voiceFeatures = read.csv(FILENAME) %>%
  left_join(voiceActivity@values)
colnames(voiceFeatures) = gsub("\\.", "_", colnames(voiceFeatures))
voiceFeatures = voiceFeatures %>%
  dplyr::select(SOURCE_ROW_ID, SOURCE_ROW_VERSION, healthCode, externalId, uploadDate, createdOn, appVersion, phoneInfo,
                momentInDayFormat_json_choiceAnswers, momentInDayFormat_json_questionTypeName,
                momentInDayFormat_json_questionType, momentInDayFormat_json_item, 
                momentInDayFormat_json_endDate, momentInDayFormat_json_startDate, 
                momentInDayFormat_json_answer, momentInDayFormat_json_saveable, calculatedMeds,
                recordId, Median_F0, Mean_Jitter, Median_Jitter, Mean_Shimmer, Median_Shimmer,
                MFCC_Band_1, MFCC_Band_2, MFCC_Band_3, MFCC_Band_4, MFCC_Jitter_Band_1_Positive,
                MFCC_Jitter_Band_2_Positive, MFCC_Jitter_Band_3_Positive, MFCC_Jitter_Band_4_Positive)

# Get stored features from synapse
existingVoiceFeatures_schema = synGet(FEATURE_ID)
existingVoiceFeatures_values = synTableQuery(paste('select * from', FEATURE_ID))@values

if (dim(existingVoiceFeatures_values)[1] > 0){
  # Filter exisitng featureset
  voiceFeatures = dplyr::anti_join(voiceFeatures, existingVoiceFeatures_values, by = c("SOURCE_ROW_ID", "SOURCE_ROW_VERSION", "recordId"))
}

if (dim(voiceFeatures)[1] > 0){
  # Store feature set in synapse tables
  tableColumns = as.tableColumns(voiceFeatures);
  table = Table(existingVoiceFeatures_schema, tableColumns$fileHandleId) %>% synStore(retrieveData = F)
}