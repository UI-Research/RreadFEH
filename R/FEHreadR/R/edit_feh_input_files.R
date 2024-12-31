

#' Reads ALTER statements from rundynasipp.inp into a data frame.
#'
#' @param fname path for a rundynasipp.inp file
#'
#' @return dataframe with columns "TSNAME","YEAR","VALUE"
#'
#' @export
#'
feh_read_alters <- function(fname)
{
    inpLines <- readLines(fname)
    inpLines <- grep("^[[:space:]]*ALTER", inpLines, value=T)
    inpLines <- trimws(
        gsub("ALTER",
             "",
             gsub(';', "", inpLines)),
        which="both")
    inpLines <- gsub("\\)"," ",
                     gsub("\\("," ",inpLines))
    inpLines <- gsub("[[:space:]]+"," ", inpLines)
    inp_con <- textConnection(inpLines)
    df <- utils::read.table(inp_con,
                     col.names = c("TSNAME","YEAR","VALUE"),
                     colClasses = c("character","integer","numeric"),
                     na.strings = c("n/a"))
    return(df)
}

#' Writes a new input file with updated ALTER statements
#'
#' @param lines character vector with lines from the original input files
#' @param df dataframe with columns: "TSNAME", "YEAR", "VALUE"
#' @param fname the name of the new input file
#'
#' @return NA
#'
feh_write_new_input <- function(lines, df, fname) {
    outf <- file(fname, open="w+")
    cur_ts <- ""
    for(l in lines) {

        if(!grepl("^[[:space:]]*ALTER", l)) {
            cat(l,"\n", file=outf)
        }
        else {
            p <- unlist(strsplit(
                gsub("\\s*ALTER\\s+([[:alnum:]]+)\\s*\\(\\s*([[:digit:]]+)\\s*\\)\\s+.*",
                     "\\1,\\2",
                     l),
                ",")
            )
            if(p[1] != cur_ts) {
                cur_ts <- p[1]
                ts_df <- df[df$TSNAME == cur_ts,]
                nls <- apply(ts_df,
                             1,
                             function(x) paste0(" ALTER ",
                                                x[1],
                                                " (",
                                                x[2],
                                                ") ",
                                                format(x[3], digits=7),
                                                ";\n")
                )
                cat(nls, file=outf, sep="")
            }
        }
    }
    close(outf)
}

#' Compares the updated and initial dataframes with ALTERs
#'
#' @param df dataframe with columns: "TSNAME", "YEAR", "VALUE.x", "VALUE.y", "VALUE"
#'
#' @return NA
#'
print_diff <- function(df)
{
    not_in_ts <-unique(df[is.na(df$VALUE.x), "TSNAME"])
    not_tr_ts <-unique(df[is.na(df$VALUE.y), "TSNAME"])
    not_in <-df[is.na(df$VALUE.x), c("TSNAME","YEAR")]
    not_tr <- df[is.na(df$VALUE.y), c("TSNAME","YEAR")]

    print("Values in new ALTER data, but not in the current input file")
    for(i in not_in_ts) {
        print(i)
        print(not_in[not_in$TSNAME==i,"YEAR"])
    }

    print("Values in the current input file, but not in new ALTER data")
    for(i in not_tr_ts) {
        print(i)
        print(not_tr[not_tr$TSNAME==i,"YEAR"])
    }
}

#' Creates a new version of input file with updated ALTER statements
#'
#' @param alterdf dataframe with new ALTERs and columns: "TSNAME", "YEAR", "VALUE"
#' @param infname initial input file path
#' @param outfname the path of the new input file
#'
#' @return NA
#'
#' @export
#'
feh_update_alters = function(alterdf, infname, outfname)
{

    # Read the the input file lines
    inpLines <- readLines(infname)

    # Read alters input file into data frames
    alterdf0 <- feh_read_alters(infname)

    # Merge the data frames
    df = dplyr::full_join(alterdf0, alterdf, by=c("TSNAME","YEAR"))

    # If trustees' value exists use it;
    # otherwise use the input file value
    df = dplyr::mutate(df, VALUE = dplyr::if_else(!is.na(VALUE.y), VALUE.y, VALUE.x))

    # Print differences in two sets
    print_diff(df)

    # Write a new input file
    feh_write_new_input(inpLines, dplyr::select(df, "TSNAME","YEAR","VALUE"), outfname)
}
