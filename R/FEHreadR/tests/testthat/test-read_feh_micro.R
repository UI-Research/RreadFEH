
test_that("read_header() reads starting sample header", {
    hdrfile = test_path("fixtures", "dynasipp_HEADER.dat")
    res = read_header(hdrfile)
    expect_length(res, 2)
})

test_that("read_header() reads output header", {
    hdrfile = test_path("fixtures", "dynasipp_header_even.dat")
    res = read_header(hdrfile)
    expect_length(res, 2)
})

test_that("read_in_frame() reads a frame", {
    hdrfile = test_path("fixtures", "dynasipp_HEADER.dat")
    f <- file(hdrfile, "rb")
    # Read first 4 bytes
    # - In the starting sample, they contain the year as an integer
    # - In the output sample, the year is located in bytes 7-10 as ASCII
    #
    year = readBin(f, what="int", size=4, n=1)
    famrec = read_in_frame(f)
    perrec = read_in_frame(f)
    close(f)
    expect_length(famrec, 4)
    expect_length(perrec, 4)
    expect_equal(famrec[['nmts']],0)
})

test_that("feh_wide_to_long() converts to long", {
    fname = test_path("fixtures", "fehout_10obs.csv")
    widedf = read.csv(fname) |>
        dplyr::select(tidyselect::starts_with(c(
            "PERNUM",
            "EARNINGS",
            "SAVINGS1"
            ))
        )
    df = feh_wide_to_long(widedf)
    expect_equal(dim(df)[2],4)
    expect_equal(dim(dplyr::filter(df, is.na(year)))[1], 0)
    expect_equal(dim(dplyr::filter(df, is.na(earnings)))[1], 0)
})
