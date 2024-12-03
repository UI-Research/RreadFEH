
<!-- README.md is generated from README.Rmd. Please edit that file -->

# FEHreadR

<!-- badges: start -->
<!-- badges: end -->

FEHreadR provides a set of functions for reading and manipulating files
created by DYNASIM’s FEH module.

## Installation

You can install the development version of FEHreadR from
[GitHub](https://github.com/) with:

``` r
# install.packages("devtools")
devtools::install_github("UI-Research/RreadFEH/R/FEHreadR")
```

## Examples

To read a binary file produced by FEH (fehdir needs to contain
`dynasipp_header_even.dat` and `dynasipp_person_even.dat`):

``` r

library(FEHreadR)

fname = "tmp.csv"
widedf = read_feh(fehdir, obs_count=100)
write.csv(widedf, fname)
```

To convert an FEH dataframe from wide to long format:

``` r
library(FEHreadR)

widedf = read.csv(fname) |>
    dplyr::select(tidyselect::starts_with(c(
        "PERNUM",
        "EARNINGS",
        "SAVINGS1"
        ))
    )
longdf = feh_wide_to_long(widedf)
```

To read alter statements from an FEH input file:

``` r
library(FEHreadR)

df = feh_read_alters(fname)
```

To update alter statements from an FEH input file and create a new input
file:

``` r
library(FEHreadR)

alterdf = data.frame(
    TSNAME="EARNTRG",
    YEAR=2025:2030,
    VALUE=50000
)

df = feh_update_alters(alterdf, infname, outfname)
```
