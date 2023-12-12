
library(tidyverse)

source("read_codebook.R")

fehdir = "//SAS1/Dynasim/FEHOutput/run_01004/"
fehfile <- paste0(fehdir, "dynasipp_person_even.dat")
codebookfile = paste0(fehdir, "codebook_2100ds.sipp2006")

# Read the codebook
rec_struct <- get_col_names(codebookfile)
rec_len <- length(rec_struct)

# FEH file size
feh_file_size <- file.size(fehfile)

# FEH number of records
rec_num <- feh_file_size/4/rec_len

# Number of observations to read
obs_num <- rec_num
obs_num <- 1000
read_len <- obs_num * rec_len

# Read raw FEH data
system.time(
  rawdata <- readBin(fehfile, "integer", read_len, 4)
)

# Convert raw data into a matrix
system.time(
  feh_mat <- matrix(rawdata, nrow=obs_num, ncol=rec_len, byrow = T)
)
colnames(feh_mat) <- rec_struct

# Convert to data frame
system.time(
  feh_df <- as.data.frame(feh_mat)
)
# tmp_df <- select(feh_df, PERNUM, SEX)

# Convert to data table
# system.time(
#   feh_df <- as.data.table(feh_mat)
# )
# user  system elapsed 
# 7.33    4.30   11.72 