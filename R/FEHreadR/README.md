
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

## Example

To convert an FEH dataframe from wide to long format:

``` r
library(FEHreadR)

longdf = feh_wide_to_long(widedf)
```
