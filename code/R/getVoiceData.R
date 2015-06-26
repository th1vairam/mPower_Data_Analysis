# Function to download m4a formated voice data from synapse
getVoiceData <- function(rowIds, table, columnName) {
  nas <- is.na(table@values[rowIds, columnName])
  fnms <- NULL
  rowIds <- rowIds[!nas]
  if (sum(!nas) > 0) {
    fnms <- sapply(rowIds, function(x){
      try(synDownloadTableFile(table, x, columnName),
        silent = T
        )})
  }
  list(fnms = fnms, nas = rowIds[nas])
}