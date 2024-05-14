# DEATH Simulation Model

# Step 1: Create a Test Structured Array with the necessary fields

# Step 2: Code the model

# create death model + parallelize with numba! 

# Packages
import math

# Global Variables
MAXAGE = 120
MAXAGS = 121

def ylgods(nvars: int, ylc: int, yval: int, labs: str, qdb: bool) -> int:
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
        xp: an integer containing the resulting probability
    """
    xb = 0.0
    for i in range(nvars):
        xb = xb + ylc[i] * yval[i]
    if xb < -87.0:
        xb = -87.0
    xp = 1 / (1 + math.exp(-1 * xb))
    return(xp)

# Read in Input File
