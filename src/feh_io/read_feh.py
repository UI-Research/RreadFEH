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
import numpy.lib.recfunctions as rf
import pyarrow.parquet as pq # for parquet file format
import pyarrow as pa # for pyarrow functions format
import pandas as pd

def make_record_dict(file:io.BufferedReader, sample:str):
    """Reads a section of a header file and creates a record dictionary

    Args:
        file (io.BufferedReader): a file object pointing to the 
        beginning of a header section.
        sample (str): 'input' or 'output' to indicate the type of sample

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

    if sample == "output":
        nsat, nmat, rlen, nmts = struct.unpack('2x10s10s10s10s2x', file.read(44))
        #print(int.from_bytes(nsat, byteorder="little", signed=True))
        res['nsat'] = int(nsat)
        res['nmat'] = int(nmat)
        res['rlen'] = int(rlen)
        res['nmts'] = int(nmts)

    elif sample == "input":
        unused = np.fromfile(file, dtype=np.uint8, count=2)
        frame = np.fromfile(file, dtype=np.int32, count=4)
        unused = np.fromfile(file, dtype=np.uint8, count=2)
        res = {
        "nsat": frame[0],
        "nmat": frame[1],
        "rlen": frame[2],
        "nmts": frame[3]
        }
    # Create names list
    res['names'] = [''] * res['nsat']
    for i in range(res['nsat']):
        res['names'][i] = str(file.read(8), 'utf-8')

    # If there is at least 1 time series variable, initialize 0 vectors to be filled later
    if res['nmts'] > 0:
        file.read(2)
        res['mtsnm'] = [0]*res['nmts']
        res['mtsly'] = [0]*res['nmts']
        res['mtshy'] = [0]*res['nmts']
        res['mtsp']  = [0]*res['nmts']

        # Populate mtsp, mtsly, mtshy, mtsp 0 vectors, read bytes as integers
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
    names = [n.strip() for n in rec['names']]

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
       Presumes the first 4 bytes of the starting sample file are '2006' and first 10 bytes of 
       output sample are '2060'. If neither condition satisfied, error is raised.

    Args:
        filename (str): the path to a DYNASIM header file

    Returns:
        tuple: (year, family-record dict, person-record dict)
    """

    # Open header file
    with open(filename, 'rb') as file:
        # Get the first 10 bytes
        first_10_bytes = file.read(10)

        ### CONDITIONS TO IDENTIFY INPUT FILE
        # Check if the 5th and 6th bytes are '\x0D\x0A' representing a new line in the file
        in_year_byte_suffix = first_10_bytes[4:6]
        # Check if the first 4 bytes of the first 10 represent a year between 2000 and 2100
        in_year_bytes = int.from_bytes(first_10_bytes[:4], byteorder="little", signed=True)
        input_conditions = 2000 <= in_year_bytes <= 2100 and in_year_byte_suffix == b'\x0D\x0A'

        ### CONDITIONS TO IDENTIFY OUTPUT FILE
        # Check if first 6 bytes represent empty space designated by 0x20202020
        output_conditions = first_10_bytes[:6] == b'\x20\x20\x20\x20\x20\x20'

        if input_conditions:
            sample = 'input'
            year = int.from_bytes(first_10_bytes[:4], byteorder="little", signed=True)
            # Go back to the 4th byte to ensure the file is in the correct place
            file.seek(4)
        
        # Check if the first 10 bytes represent the year 2060
        elif output_conditions:
            # If output sample, need to move 6 more bytes
            sample = 'output'
            year = int(first_10_bytes)
        
        # If neither condition is met, raise an error
        else:
            raise ValueError( 'Invalid year in file header or invalid format in first 10 bytes of file:\n'
                              'The first 4 bytes should contain a year and the following 5th and 6th should define a new line in input data\n'
                              'This year should be between 2000 and 2100\n\n'
                              'The last 4 bytes should contain a year and the first 6 should contain empty space in output data\n'
                              'This year should be between 2060 and 2200\n\n'
                              f'First ten bytes, raw: {first_10_bytes}' )

        # Advance through header file in order of where family and person records are stored
        # Make family-record dictionary
        famrec = make_record_dict(file, sample = sample)

        # Make person-record dictionary
        perrec = make_record_dict(file, sample = sample)

    return year, famrec, perrec

def select_vars(data, var_list:list):
    """Selects a var from a structured array and repacks array
       Repacking removes unnecessary padding bytes.

    Args:
        data (np.array): a processed DYNASIM data file
        var_list (list): a list of variables to select from the data file

    Returns:
        numpy structured array: data
    """
    try:
        # Subset to selected vars
        data = data[var_list]
        # Repack fields to ensure consistency between data formats
        # Otherwise numpy will do some transformations to the structured array after subsetting
        data = rf.repack_fields(data)

    except:
        missing_vars = [var for var in var_list if var not in data.dtype.names]
        raise ValueError(f"Fields missing from the data:\n{missing_vars}\n"
                         f"\nAvailable variables are:\n{data.dtype.names}")
    
    return data

def read_feh_data_file(
        header_file:str, 
        data_file:str,
        var_list:list = None,
        file_type:str = 'person', 
        count:int = -1,
        offset:int = 0):
    """Reads a DYNASIM data file

    Args:
        header_file (str): the path to a DYNASIM header file
        data_file (str): the path to a DYNASIM data file
        file_type (str): 'person' or 'family' file. Defaults to 
            'person'.
        count (int, optional): number of records to read, all if -1. 
            Defaults to -1.
        offset (int, optional): number of bytes to skip before reading.
            Defaults to 0.

    Returns:
        numpy structured array: data
    """

    # Initialize family and person dictionaries and numeric year
    year, famrec, perrec = read_header_file(header_file)
    
    if file_type == 'person':
        rectype = make_rec_dtype(perrec)

    elif file_type == 'family':
        rectype = make_rec_dtype(famrec)

    else:
        raise ValueError(f"file_type can be 'person' or 'family' but not {file_type}")
    
    data = np.fromfile(data_file, dtype=rectype, count=count, offset=offset)

    # Change name to reflect names in varlist, if provided
    if var_list is not None:
        data = select_vars(data, var_list)
    
    return data

def feh_wide_to_long(widearr):
    """Creates a long-format array for longitudinal variables in widearr

    Args:
        widearr (np.array): structured numpy array with longitudinal variables and "PERNUM"

    Returns:
        structured numpy array: long-format array with longitudinal variables from widearr
    """

    # List of years in the longitudinal variables
    years = np.unique([int(x[-4:]) for x in widearr.dtype.names if x[-4:].isdigit()])

    # The list of longitudinal variables in the wide format
    mtswide = [x for x in widearr.dtype.names if x[-4:].isdigit()]

    # The list of longitudinal variable names
    mtslong = set([x[:-4] for x in mtswide])
    mtslong = [x.lower() for x in mtslong]

    # The list of variable names for the long array
    longnames = ['year', 'pernum']
    longnames.extend(mtslong)

    # Dimensions
    nper = widearr.shape[0]
    nmtsw = len(mtswide)
    nyears = len(years)
    nrow = nper * nyears

    # Create an empty array
    rectype = np.dtype({'names':longnames, 'formats': ['i4']*len(longnames)})
    longarr = np.zeros(nrow, rectype)

    # Fill in pernum and year
    longarr['pernum'] = np.tile(widearr['PERNUM'], nyears)
    longarr['year']   = np.repeat(np.array(years), nper)

    # For each year, fill in the rest of the variables
    for y, year in enumerate(years):
        yl = y*nper
        yh = (y+1)*nper
        yvarsw = [var for var in mtswide if str(year) in var]
        yvarsl = [x[:-4].lower() for x in yvarsw]
        longarr[yvarsl][yl:yh] = widearr[yvarsw]

    return longarr

def print_offsets(d):

    print("offsets:", [d.fields[name][1] for name in d.names])

    print("itemsize:", d.itemsize)

def structured_shape(x):
    if len(x.dtype) > 0:
        return list(x.shape) + [len(x.dtype)]
    else:
        return x.shape

# Attempt 1- read parquet file then convert to structured numpy array
def read_parquet_1(file_path:str):
    """Reads a parquet-format array created by save_feh_parquet() 
       and converts it to a structured numpy array.

    Args:
        file_path (str): path to read the data from parquet. 

    Returns:
        structured numpy array: data 
    """
    # Step 1: Read the Parquet file into a PyArrow Table
    table_test = pq.read_table(file_path)

    # Step 2: Extract schema information
    columns = table_test.column_names
    types = table_test.schema.types

    # Step 3: Define a mapping between PyArrow types and NumPy types
    arrow_to_numpy_dtype = {
        pa.int8(): np.int8,
        pa.int16(): np.int16,
        pa.int32(): np.int32,
        pa.int64(): np.int64,
        pa.uint8(): np.uint8,
        pa.uint16(): np.uint16,
        pa.uint32(): np.uint32,
        pa.uint64(): np.uint64,
        pa.float32(): np.float32,
        pa.float64(): np.float64,
        pa.string(): 'U',  # Unicode string
    }

    # Step 4: Create a structured array dtype
    dtype = [(col, arrow_to_numpy_dtype[type_]) for col, type_ in zip(columns, types)]

    # Step 5: Convert PyArrow Table to a dictionary of NumPy arrays
    data = {col: table_test[col].to_numpy() for col in table_test.column_names}

    # Step 6: Create a structured NumPy array from the dictionary
    structured_array = np.empty(len(table_test), dtype=dtype)
    for col in table_test.column_names:
        structured_array[col] = data[col]

    return structured_array

# Attempt 2- read parquet file then convert to structured numpy array using default pandas functionality
# Slightly more efficienct than attempt 1 it seems, still less efficient than binary
def read_parquet_2(file_path):
    """Reads a parquet-format array created by save_feh_parquet() 
       and converts it to a structured numpy array.

    Args:
        file_path (str): path to read the data from parquet. 

    Returns:
        structured numpy array: data 
    """
    # Step 1: Read the Parquet file into a pandas DataFrame
    df = pq.read_table(file_path).to_pandas()

    # Step 2: Convert the DataFrame to a structured numpy array
    structured_array = df.to_records(index=False)

    return structured_array