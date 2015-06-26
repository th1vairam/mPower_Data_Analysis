# Function to convert m4a files to wav format
require(tuneR)

Files.Present = list.files(path='/mPower', pattern='*.tmp', recursive=T)

m4a.file = paste('/mPower',Files.Present[1],sep='/')
wav.file = paste(tools::file_path_sans_ext(tmp),'wav',sep='.')

system(paste('avconv','-i',m4a.file,wav.file))

tmp = readWave(wav.file)

Files.Processed = c(Files.Processed, tmp)