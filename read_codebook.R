
# This file contains functions that parse FEH codebook and return
# a data frame that contains a list of names of record fields, its
# types (scalar or array) and index ranges for arrays.


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
