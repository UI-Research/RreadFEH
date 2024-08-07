"""
Functions for saving DYNASIM-FEH output files.

DYNASIM FEH produces three files:

    - header file,
    - family file, and
    - person file.


The header file contains specifications of both family and person
records. The function that reads DYNASIM data is read_feh_data_file. 
It requires paths to a header file and to one of the two data files.
"""
import struct
import numpy as np
import os
import io
import numpy.lib.recfunctions as rf
import read_feh

def save_feh_csv(data, out_path:str, filename:str):
    """Saves a structured numpy array to a .csv file

    Args:
        data (np.array): structured numpy array
        out_path (str): path to save the data
        filename (str): name of the file to save the data as

    Returns:
        nothing: saves the data to a .csv file
    """
    # Combine the output_path and filename into a single path
    file_path = os.path.join(out_path, f'{filename}.csv')

    # Get the names of the fields in the structured array
    names = data.dtype.names

    # Check to see if the provided out path exists
    assert os.path.isdir(os.path.dirname(out_path)), f"""
    The directory of the file path {out_path} does not exist. Try again.
    
    Use a filepath for the out_path argument relative to the current directory: {os.getcwd()}.

    For example, if you want to save in '{os.getcwd().replace('\\', '/')}/data/output/' use 'data/output/'.
    """

    # Save the data to a .csv file
    np.savetxt(file_path, data, delimiter=",", header=",".join(names), comments='', fmt='%s')

    return

def save_feh_parquet(data, out_path:str, filename:str):
    """Saves a structured numpy array to a .dat file

    Args:
        data (np.array): structured numpy array
        out_path (str): path to save the data ex. 
        filename (str): name of the file to save the data as

    Returns:
        nothing: saves the data to a .dat file
    """
    # Combine the output_path and filename into a single path
    file_path = os.path.join(out_path, filename)

    # Check to see if the provided out path exists
    assert os.path.isdir(os.path.dirname(out_path)), f"""
    The directory of the file path {out_path} does not exist. Try again.
    
    Use a filepath for the out_path argument relative to the current directory: {os.getcwd()}.

    For example, if you want to save in '{os.getcwd().replace('\\', '/')}/data/output/' use 'data/output/'.
    """

    # Save the data to a .dat file
    data.tofile(file_path)
    print(f"Saved data to {file_path}")

    return