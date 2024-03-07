
library(tidyverse)


#' Returns a vector of field types
#'
#' @param lines Character vector of codebook lines
#' @return A vector of field types
get_record_types <- function(lines)
{
    scalar_line_numbers <- grep("[[:space:]]*V-[[:space:]]*[[:alnum:]]+[[:space:]]+", lines)
    array_line_numbers <- grep("[[:space:]]*V-[[:space:]]*[[:alnum:]]+\\(", lines)
    rec_type <- character(length(lines))
    rec_type[scalar_line_numbers] <- "scalar"
    rec_type[array_line_numbers] <- "array"
    return(rec_type)
}

#' Parse codebook lines into a dataframe of names, types and array ranges
#'
#' @param lines Character vector of codebook lines
#' @return A dataframe with variables: name, type, start, stop
parse_codebook_lines <- function(lines)
{
    per_names <- sub("[[:space:]]*V-[[:space:]]*([[:alnum:]]+)[[:space:](].*", "\\1", lines)
    rec_type <- get_record_types(lines)
    array_year_range <- sub("[[:space:]]*V-[[:space:]]*[[:alnum:]]+[[:space:]]+.*","", lines)
    array_year_range <- sub("[[:space:]]*V-[[:space:]]*[[:alnum:]]+\\(([[:digit:]]+\\-[[:digit:]]+)\\).*","\\1", array_year_range)
    array_year_start <- as.integer(sub("([[:digit:]]+)\\-.*","\\1", array_year_range))
    array_year_end   <- as.integer(sub("[[:digit:]]+\\-([[:digit:]]+).*","\\1", array_year_range))
    return(data.frame(name=per_names, type=rec_type, start=array_year_start, end=array_year_end))
}

#fam_df <- parse_codebook_lines(fam_rec_lines)

#' Parse person record codebook
#'
#' @param fname The codebook file name
#' @return A dataframe with variables: name, type, start, stop
parse_person_codebook <- function(fname)
{
    codebook_text <- readLines(fname)

    fam_rec_start <- grep("[[:space:]]*RECORD- FAMILY", codebook_text)
    per_rec_start <- grep("[[:space:]]*RECORD- PERSON", codebook_text)
    endvars <- grep("[[:space:]]*ENDVARS", codebook_text)

    if(!(endvars[1] > fam_rec_start & endvars[1] < per_rec_start & endvars[2] > per_rec_start)) {
        stop("ERROR: Codebook invalid")
    }

    per_rec_lines <- codebook_text[(per_rec_start+1):(endvars[2]-1)]
    per_rec_lines <- grep("[[:space:]]*V-", per_rec_lines, value = T)

    return(parse_codebook_lines(per_rec_lines))
}

#' Parse family record codebook
#'
#' @param fname The codebook file name
#' @return A dataframe with variables: name, type, start, stop
parse_family_codebook <- function(fname)
{
    codebook_text <- readLines(fname)

    fam_rec_start <- grep("[[:space:]]*RECORD- FAMILY", codebook_text)
    per_rec_start <- grep("[[:space:]]*RECORD- PERSON", codebook_text)
    endvars <- grep("[[:space:]]*ENDVARS", codebook_text)

    if(!(endvars[1] > fam_rec_start & endvars[1] < per_rec_start & endvars[2] > per_rec_start)) {
        stop("ERROR: Codebook invalid")
    }

    fam_rec_lines <- codebook_text[(fam_rec_start+1):(endvars[1]-1)]
    fam_rec_lines <- grep("[[:space:]]*V-", fam_rec_lines, value = T)

    return(parse_codebook_lines(fam_rec_lines))
}

df_to_col_names <- function(df)
{
    rec_struct <- as.character(df$name)

    arrays_df <- df %>%
        filter(type=="array") %>%
        select(name, start, end)

    rec_struct <- c(rec_struct,
                    unlist(apply(arrays_df, 1, function(x) paste0(x[1], x[2]:x[3]))))
}

get_col_names = function(codebook)
{
    per_df <- parse_person_codebook(codebook)
    col_names <- df_to_col_names(per_df)
    return(col_names)
}


#' Reads DYNASIM codebook and FEH persons file
#'
#' @param codebookfile the path to an FEH codebook
#' @param fehfile the path to an FEH persons file
#' @param columns(optional) character vector of column names to keep; all if NULL (default)
#' @param obs_count the number of observations to read; all if NA (default)
read_feh_cbk = function(codebookfile, fehfile, columns=NULL, obs_count=NA)
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

#' Converts DYNASIM FEH output data from wide to long format.
#' It also changes the column names into lower case.
#'
#' @param data DYNASIM FEH dataset as returned by read_feh
#'
feh_wide_to_long = function(data)
{
    # Time-series names
    tsnames = tolower(unique(gsub("\\d{4}", "", grep("[A-Z]+\\d{4}", keep_cols, value = TRUE))))
    match_pat = paste(paste0(tsnames, ".*"), collapse="|")
    names_pat = paste0("(", paste(tsnames, collapse = "|"), ")(\\d+)")

    df = data |>
        rename_with(tolower) |>
        pivot_longer(
            matches(match_pat),
            names_to=c('.value', 'year'),
            names_pattern=(names_pat)
        ) |>
        mutate(year=as.integer(year))

    return(df)
}

#' Reads from an open FEH header file and returns a record structure
#' 
#' @param file a connection to a header file pointing to a beginning of a header
#' 
make_record_struct <- function(file) {
  
  # Read binary data from file
  bin_data <- readBin(file, what = "raw", n = 44)
  
  # Unpack binary data
  nsat <- as.integer(rawToChar(bin_data[3:12]))
  nmat <- as.integer(rawToChar(bin_data[13:22]))
  rlen <- as.integer(rawToChar(bin_data[23:32]))
  nmts <- as.integer(rawToChar(bin_data[33:42]))
  
  # Create result dictionary
  res <- list(
    nsat = nsat,
    nmat = nmat,
    rlen = rlen,
    nmts = nmts
  )
  
  # Read variable names
  res$names <- vector(mode = "character", length = res$nsat)
  for (i in seq_len(res$nsat)) {
    res$names[i] <- readChar(file, 8, useBytes = TRUE)
  }
  
  # Read MTS variables if nmts > 0
  if (res$nmts > 0) {
    readBin(file, "integer", size=2, n = 1) # Skip 2 bytes
    res$mtsnm <- numeric(res$nmts)
    res$mtsly <- numeric(res$nmts)
    res$mtshy <- numeric(res$nmts)
    res$mtsp <- numeric(res$nmts)
    for (i in seq_len(res$nmts)) {
      res$mtsnm[i] <- as.integer(readBin(file, "integer", size=4, n = 1))
    }
    for (i in seq_len(res$nmts)) {
      res$mtsly[i] <- as.integer(readBin(file, "integer", size=4, n = 1))
    }
    for (i in seq_len(res$nmts)) {
      res$mtshy[i] <- as.integer(readBin(file, "integer", size=4, n = 1))
    }
    for (i in seq_len(res$nmts)) {
      res$mtsp[i] <- as.integer(readBin(file, "integer", size=4, n = 1))
    }
  }
  
  return(res)
}

#' Creates a vector of column names from a header record
#' 
#' @param rec record structure returned by make_record_struct
#' 
make_col_names <- function(rec) {
  # Start with all variable names--these are scalar variables
  names <- trimws(rec$names)
  
  # Now add MTS variables
  for (i in seq_len(rec$nmts)) {
    # MTS variable name
    mtsname <- names[rec$mtsnm[i]]
    
    # Combine MTS name with all the years from its range
    mtsnames <- paste0(mtsname, rec$mtsly[i]:rec$mtshy[i])
    
    names <- c(names, mtsnames)
  }
  
  # Return the dtype list
  return(names)
}

#' Reads an FEH header file and returns its record structures
#' 
#' @param hdrfile the path to a header file
#' 
read_header = function(hdrfile)
{
  
  file <- file(hdrfile, "rb")
  year = readBin(file, what="raw", n=10)
  year = as.integer(rawToChar(year))
  
  famrec <- make_record_struct(file)
  perrec <- make_record_struct(file)
  close(file)
  res = list(
    famrec=famrec,
    perrec=perrec
  )
  return(res)
}



#' Reads FEH header and data files
#' 
#' File names must follow the following convention:
#'  header: dynasipp_header_[even|odd].dat
#'  data:   dynasipp_[person|family]_[even|odd].dat
#'
#' @param fehdir the folder containing the header and data files
#' @param even (optional) read even-year files; otherwise, read odd-year files
#' @param person (optional) 
#' @param columns(optional) character vector of column names to keep; all if NULL (default)
#' @param obs_count the number of observations to read; all if NA (default)
read_feh = function(fehdir, even=TRUE, person=TRUE, columns=NULL, obs_count=NA)
{
  year_sfx = ifelse(even,  'even',  'odd')
  type_sfx = ifelse(person,'person','family')
  
  hdrfile = paste0(fehdir, '/dynasipp_header_', year_sfx, '.dat')
  datfile = paste0(fehdir, '/dynasipp_', type_sfx, '_', year_sfx, '.dat')
  
  stopifnot(file.exists(hdrfile))
  stopifnot(file.exists(hdrfile))

  # Read the header
  hdr = read_header(hdrfile)  
  if( person ) {
    rec=make_col_names(hdr$perrec)
  } 
  else {
    rec=make_col_names(hdr$famrec)
  }
  rec_len <- length(rec)
  
  # FEH file size
  feh_file_size <- file.size(datfile)
  
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
  
  fehcon = file(datfile, "rb")
  obs_read=0
  while(obs_read<obs_count) {
    
    read_count = pmin(obs_count-obs_read, chunk_size)
    read_len = read_count * rec_len
    
    # Read raw FEH data
    cat("Reading next ", format(read_count, width=6), " observations...")
    rawdata <- readBin(fehcon, "integer", read_len, 4)
    
    # Convert raw data into a matrix
    feh_mat <- matrix(rawdata, nrow=read_count, ncol=rec_len, byrow = T)
    
    colnames(feh_mat) <- rec
    
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
test=FALSE
if(example) {
    fehdir = "S:/damir/run_1004/"
    fehfile <- paste0(fehdir, "dynasipp_person_even.dat")
    codebookfile = paste0(fehdir, "codebook_2100ds.sipp2006")
    keep_cols = c('PERNUM', 'DOBY', 'SEX', 'RACE', 'ETHNCTY', 'YEARDIED', paste0('GRADECAT', 2006:2100))
    df = read_feh(codebookfile, fehfile, columns=keep_cols)
}
if(test) {
  
  # Compare data read by read_feh_cbk and read_feh  
  
  df1 = read_feh(
    "X:/FEHOutput/run_01006/base_v5",
    obs_count=1e4
  )
  
  df2 = read_feh_cbk(
    "C:/Users/dcosic/Dynasim/Dynasim-babybonds/Dynasim-core/run/codebook_2100ds.sipp2006",
    "X:/FEHOutput/run_01006/base_v5/dynasipp_person_even.dat",
    obs_count=1e4
  )
  
  ncols = dim(df1)[2]
  
  testpass=TRUE
  for(i in seq_len(ncols)) {
    if( ! all(df1[i]==df2[i], na.rm=TRUE) ) {
      testpass = FALSE
      print(paste0("Column ", i, " differs"))
    }
  }
  if(testpass) {
    print("Test passed")
  }
}  


