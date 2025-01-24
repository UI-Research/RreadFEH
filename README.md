This repo contains R and Python code that reads the output of DYNASIM's Family and Earnings History (FEH) module. 

## Python

The Python reader is implemented in the module `feh_io`. To install it from Github, execute the following command:
```
pip install feh_io@git+https://github.com/UI-Research/RreadFEH/
```

The function `read_feh_data_file()` is all that is needed for reading a DYNASIM file. For example:

```
import feh_io

header_file = 'C:/Users/dcosic/Documents/Dynasim/Dynasim-core/run/dynasipp_header_even.dat'
person_file = 'C:/Users/dcosic/Documents/Dynasim/Dynasim-core/run/dynasipp_person_even.dat'
family_file = 'C:/Users/dcosic/Documents/Dynasim/Dynasim-core/run/dynasipp_family_even.dat'

# Read 10 records from each person and family file
perdata = feh_io.read_feh_data_file(header_file, person_file, file_type='person', count=10)
famdata = feh_io.read_feh_data_file(header_file, family_file, file_type='family', count=10)

```

## R

To install the R package, execute the following command:

```
# If you don't have "devtools", first install this package
# install.packages("devtools")

devtools::install_github("UI-Research/RreadFEH/R/FEHreadR")

```
