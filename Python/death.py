"""
Programmer: Thiyaghessan
Date created: 2024-04-03
Date of last revision: 2024-05-14
Ancestor Program: [Path to the program including the name of the program]
original data: 
Input Files: sample/input/ 
Output Files: sample/output/
DEATH.FOR: https://github.com/UI-Research/Dynasim-core/blob/c02e4609d3418a278b219ec59402f611d604b8c1/source/FEH/DEATH.FOR#L4
Description: This script rewrites DEATH.FOR in python.
"DEATH" determines whether a person will die.
"""

# Packages
import math
from read_feh import read_feh_data_file
import numpy as np

# Global Variables
MAXAGE = 120
MAXAGS = 121
NAGEG = 50 # Number of Age Groups

def ylgods(ylc: int, yval: int) -> int:
    """
    YLGODS takes as input a vector of logistic coefficients and a vector of 
    variable values and returns the resulting probability. Debug mode is 
    supported, and an array of labels for the variables is required. Also
    required is an integer argument for dimensioning the arrays. The 
    intercept is assumed to be the first value in the array.

    Args:
        NVARS       -- Number of variables (including intercept)
        YLC (NVARS) -- Array of logistic coefficients
        YVAL(NVARS) -- Array of variable values
        LABS(NVARS) -- Character array of labels for vars
        QDB         -- Logical argument indicating debug mode
    Returns:
        xp: an integer containing the expected probability of death
    """
    xb = np.multiply(ylc, yval)
    xb_sum = np.sum(xb)
    xp = 1 / (1 + math.exp(-1 * xb_sum))
    return(xp)

def modify_pve_ratio(pve_array: int) -> int:
    """
    This function modifies "PVERATIO" field in the structured perdata array.

    Args:
        pve_array: Structured array containing "PVERATIO" field. int.
    Returns:
        ypve_array: Modified pve_array.
    """
    ypve_array = np.where(pve_array > 0, pve_array / 100000.0, 1.0)
    return(ypve_array)

def create_family_income(lfpart_arr: int, earnings_arr: int, famnum_arr: int) -> int:
    """
    This function creates a family income variable used in death simulations.
    
    Args:
        lfpart_arr: "LFPART" field - labor force participation rate
        earnings_arr: "EARNINGS" field - Annual earnings in 1958 dollars
        famnum_arr: "FAMNUM" field - Family number
    Returns:
        faminc_arr: "FAMINC" field - Family income summed by family number
    """
    faminc_arr = np.multiply(lfpart_arr, earnings_arr)
    return(faminc_arr)

def determine_race(sex: int, race: int) -> int:
    """
    This function takes the FAMNUM, SEX and RACE arrays
    from the input sample and return a RACETH array that codes
    each person based on race and ethnicity
    """
    zblack = np.random.rand(np.ndarray.size(race), )



def death_pers_sim(perdata: np.array, start_year: int) -> np.array:
    """
    This function runs the death simulation at the person level
    """
    current_year = start_year
    NCOEFA = 40 # Number of coefficients for adults
    YAC = np.full((NCOEFA,), 1.00)
    YAV = np.zeros((NCOEFA,), dtype = int)

    YAV[[0]] = 1
    YAV[[1]] = 0
    # Figure out race variables
    # if nnhsp == 1 or nathsp == 1: YAV[[2]] = 1

    # Load in necessary fields
    seed = perdata["PERSEED"]
    pernum = perdata["PERNUM"]
    age = perdata["AGE"]
    race = perdata["RACE"]
    sex = perdata["SEX"]
    wedstate = perdata["WEDSTATE"]
    kidsborn = perdata["KIDSBORN"]
    gradecat = perdata["GRADECAT"]
    splitid = perdata["SPLITID"]
    earnings = perdata["EARNINGS"]
    disabled = perdata["DISABLED"]
    lfpart = perdata["LFPART"]
    immigyr = perdata["IMMIGYR"]
    dipred = perdata["DIPRED"]
    # ... lines 332-347
    
    #XP = YLGODS(YAC, YAV )
    # each person gets an array



### There is a presimulation step that loads in coefficients ####

# Translate YLSTAT - each model that calls ylgods will also call ylstat and
# ylstats will update aggregate statistics for each covariate (minimum/maximum etc.)
# Can write YLSTATs as part of logging process.

if __name__ == "__main__":
    perdata = read_feh_data_file("sample/input/dynasipp_HEADER.dat", 
                                 "sample/input/dynasipp_PERSON.dat", 
                                 file_type='person', 
                                 count=10, 
                                 sample="input")
    perrecord = np.rec.array(perdata)
    rs = create_family_income(perdata["LFPART"],
                              perdata["EARNINGS"],
                              perdata["FAMNUM"])
    print(perdata["RACE"])
    
    # run_death_simulation(perdata)
