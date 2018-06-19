
library(tidyverse)
library(data.table)

setwd("D:/Users/DCosic/Box Sync/Projects/RreadFEH")
source("read_codebook.R")

fehfile <- "X:/FEHOutput/run_00958B/dynasipp_person_odd.dat"

# Read the codebook
per_df <- parse_person_codebook("D:/Users/DCosic/Box Sync/Projects/RreadFEH/codebook_2087ds.sipp2006")

get_rec_struct <- function(df)
{
  rec_struct <- as.character(df$name)
  
  arrays_df <- df %>%
    filter(type=="array") %>%
    select(name, start, end)
  
  rec_struct <- c(rec_struct, 
                  unlist(apply(arrays_df, 1, function(x) paste0(x[1], x[2]:x[3]))))
}

rec_struct <- get_rec_struct(per_df)
rec_len <- length(rec_struct)

# FEH file size
feh_file_size <- file.size(fehfile)

# FEH number of records
rec_num <- feh_file_size/4/rec_len

# Number of observations to read
obs_num <- rec_num
#obs_num <- 1000
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