"""
Functions for reading DYNASIM-FEH output files.

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
import io


def make_record_dict(file:io.BufferedReader):
    """Reads a section of a header file and creates a record dictionary

    Args:
        file (io.BufferedReader): a file object pointing to the 
        beginning of a header section.

    Returns:
        dict: A dictionary with the following elements:
            nsat: total number of variables
            nmat: NA
            rlen: NA
            nmts: number of micro-time-series (MTS) variables
            names: list of variable names
            mtsnm: list of MTS variable names as indices to names list
            mtsly: list of first years in MTS variables
            mtshy: list of last years in MTS variables
            mtsp:  list of offsets to MTS variables
    """

    res = {}

    nsat, nmat, rlen, nmts = struct.unpack('2x10s10s10s10s2x', file.read(44))
    res['nsat'] = int(nsat)
    res['nmat'] = int(nmat)
    res['rlen'] = int(rlen)
    res['nmts'] = int(nmts)

    res['names'] = [''] * res['nsat']
    for i in range(res['nsat']):
        res['names'][i] = str(file.read(8), 'utf-8')

    if res['nmts'] > 0:
        file.read(2)
        res['mtsnm'] = [0]*res['nmts']
        res['mtsly'] = [0]*res['nmts']
        res['mtshy'] = [0]*res['nmts']
        res['mtsp']  = [0]*res['nmts']
        for i in range(res['nmts']):
            res['mtsnm'][i] = struct.unpack('i', file.read(4))[0]-1
        for i in range(res['nmts']):
            res['mtsly'][i] = struct.unpack('i', file.read(4))[0]
        for i in range(res['nmts']):
            res['mtshy'][i] = struct.unpack('i', file.read(4))[0]
        for i in range(res['nmts']):
            res['mtsp'][i] = struct.unpack('i', file.read(4))[0]

    return res


def make_rec_dtype(rec:dict):
    """Creates a dtype object based on a record dictionary

    Args:
        rec (dict): a dictionary that describes a record

    Returns:
        dtype: A dtype object for a numpy structured array
    """
    
    # Start with all variable names--these are scalar variables
    names = [ n.strip() for n in rec['names']]

    # Now add MTS variables
    for i in range(rec['nmts']):

        # MTS variable name
        mtsname = names[rec['mtsnm'][i]]

        # Combine MTS name with all the years from its range
        mtsnames = [
            mtsname + str(y) for y in 
            range(rec['mtsly'][i], rec['mtshy'][i]+1)
            ]

        names.extend(mtsnames)

    # Create a dtype object for numpy structured arrays
    rectype = np.dtype({'names':names, 'formats': ['i4']*len(names)})

    return rectype

def read_header_file(filename:str):
    """Reads a DYNASIM header file and returns record dictionaries.

    Args:
        filename (str): the path to a DYNASIM header file

    Returns:
        tuple: (year, family-record dict, person-record dict)
    """

    # Open header file
    with open(filename, 'rb') as file:

        # Read year from the first 10 bytes
        year = file.read(10)
        year = int(year)

        # Make family-record dictionary
        famrec = make_record_dict(file)

        # Make person-record dictionary
        perrec = make_record_dict(file)

    return year, famrec, perrec

def read_feh_data_file(
        header_file:str, 
        data_file:str, 
        file_type:str='person', 
        count:int=-1):
    """Reads a DYNASIM data file

    Args:
        header_file (str): the path to a DYNASIM header file
        data_file (str): the path to a DYNASIM data file
        file_type (str): 'person' or 'family' file. Defaults to 
            'person'.
        count (int, optional): number of records to read, all if -1. 
            Defaults to -1.

    Returns:
        numpy structured array: data
    """

    year, famrec, perrec = read_header_file(header_file)
    
    if file_type == 'person':
        rectype = make_rec_dtype(perrec)
    elif file_type == 'family':
        rectype = make_rec_dtype(famrec)
    else:
        raise ValueError(f"file_type can be 'person' or 'family' but not {file_type}")
    
    return np.fromfile(data_file, dtype=rectype, count=count)

if __name__ == '__main__':

    header_file = 'C:/Users/dcosic/Documents/Dynasim/Dynasim-core/run/dynasipp_header_even.dat'
    person_file = 'C:/Users/dcosic/Documents/Dynasim/Dynasim-core/run/dynasipp_person_even.dat'
    family_file = 'C:/Users/dcosic/Documents/Dynasim/Dynasim-core/run/dynasipp_family_even.dat'

    perdata = read_feh_data_file(header_file, person_file, file_type='person', count=10)
    famdata = read_feh_data_file(header_file, family_file, file_type='family', count=10)

    print(perdata)
    print(famdata)

