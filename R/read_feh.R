
library(tidyverse)

source(paste0(here::here(), "/R/read_codebook.R"))

#' Reads a DYNASIM FEH persons file
#'
#' @param codebookfile the path to an FEH codebook
#' @param fehfile the path to an FEH persons file
#' @param columns(optional) character vector of column names to keep; all if NULL (default)
#' @param obs_count the number of observations to read; all if NA (default)
read_feh = function(codebookfile, fehfile, columns=NULL, obs_count=NA)
{
  
    # Read the codebook
    rec_struct <- get_col_names(codebookfile)
    rec_len <- length(rec_struct)
    
    # FEH file size
    feh_file_size <- file.size(fehfile)
    
    # FEH number of records
    rec_num <- feh_file_size/4/rec_len
    
    # Number of observations to read
    if(is.na(obs_count)) {
        obs_count <- rec_num
    }
    else if(obs_count<=0 || obs_count>rec_num) {
        stop("Invalid number of observations obs_count=", obs_count)
    }
    
    chunk_size = 50000
    
    fehcon = file(fehfile, "rb")
    obs_read=0
    while(obs_read<obs_count) {
      
        read_count = pmin(obs_count-obs_read, chunk_size)
        read_len = read_count * rec_len
        
        # Read raw FEH data
        cat("Reading next ", format(read_count, width=6), " observations...")
        rawdata <- readBin(fehcon, "integer", read_len, 4)

        # Convert raw data into a matrix
        feh_mat <- matrix(rawdata, nrow=read_count, ncol=rec_len, byrow = T)
    
        colnames(feh_mat) <- rec_struct
        
        # Convert to data frame
        df <- as.data.frame(feh_mat)
    
        if(!is.null(columns)) {
            df = select(df, all_of(columns))
        }
        
        if(obs_read == 0) {
            feh_df = df
        }
        else {
            feh_df = bind_rows(feh_df, df)
        }
        obs_read = obs_read + read_count
        cat("total =", format(obs_read, width=8, scientific=FALSE, big.mark=','), "\n")
    }
    close(fehcon)
    return(feh_df)
}

example=FALSE
if(example) {
    fehdir = "S:/damir/run_1004/"
    fehfile <- paste0(fehdir, "dynasipp_person_even.dat")
    codebookfile = paste0(fehdir, "codebook_2100ds.sipp2006")
    keep_cols = c('PERNUM', 'DOBY', 'SEX', 'RACE', 'ETHNCTY', 'YEARDIED', paste0('GRADECAT', 2006:2100))
    df = read_feh(codebookfile, fehfile, columns=keep_cols)
}

