
library(tidyverse)
library(data.table)

source("read_codebook.R")

# Read the codebook
per_df <- parse_person_codebook("../Dynasim-core/run/codebook_2100ds.sipp2006")
fam_df <- parse_family_codebook("../Dynasim-core/run/codebook_2100ds.sipp2006")

write_csv(per_df, "per_record.csv")
write_csv(fam_df, "fam_record.csv")
