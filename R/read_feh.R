
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


example=FALSE
if(example) {
    fehdir = "S:/damir/run_1004/"
    fehfile <- paste0(fehdir, "dynasipp_person_even.dat")
    codebookfile = paste0(fehdir, "codebook_2100ds.sipp2006")
    keep_cols = c('PERNUM', 'DOBY', 'SEX', 'RACE', 'ETHNCTY', 'YEARDIED', paste0('GRADECAT', 2006:2100))
    df = read_feh(codebookfile, fehfile, columns=keep_cols)
}

