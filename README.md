This repo contains R code that reads the output of DYNASIM's Family and Earnings History (FEH) module into an R data frame. Its main piece is the code in `read_codebook.R` that reads DYNASIM's codebook and constructs column names for the data frame. 

DYNASIM codebook specifies the logical layout of the person and family records. A record generally includes so called *static* variables, which contain a single value, and *micro time-series*, which contain values for a range of years. For each variable on a record, the codebook specifies its name, starting position, and end position. For micro time-series, the codebook also specifies the year range.

> [!IMPORTANT]
> All variables are 32-bit integers. The values of starting and ending position of a variable are not used.

A sample codebook is in `codebook_2087ds.sipp2006`. To obtain column names, execute the following code:

```
library(tidyverse)
source("read_codebook.R")
rec_struct <- get_col_names(paste0(here::here(), '/codebook_2087ds.sipp2006'))
```

The `read_feh.R` file contains code that reads a DYNASIM output file, but this repo does not contain any sample output files.
