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
import numpy as np
import os
import numpy.lib.recfunctions as rf
import pyarrow.parquet as pq # for parquet file format
import pyarrow as pa # for pyarrow functions format

def save_feh_parquet(data, out_path:str, filename:str):
    """Saves a structured numpy array to a .dat file

    Args:
        data (np.array): structured numpy array
        out_path (str): path to save the data ex. save
        filename (str): name of the file to save the data as

    Returns:
        nothing: saves the data to a .dat file
    """
    # Combine the output_path and filename into a single path
    file_path = os.path.join(out_path, f"{filename}.parquet")

    # Check to see if the provided out path exists
    assert os.path.isdir(os.path.dirname(out_path)), f"""
    The directory of the file path {out_path} does not exist. Try again.
    
    Use a filepath for the out_path argument relative to the current directory: {os.getcwd()}.

    For example, if you want to save in '{os.getcwd().replace('\\', '/')}/data/output/' use 'data/output/'.
    """
    # Convert the NumPy structured array to a PyArrow Table- does not natively support structured numpy arrays
    # first part collects the field names and data types from the structured array
    fields = [pa.field(name, pa.from_numpy_dtype(dtype[0])) for name, dtype in data.dtype.fields.items()]

    # Set schema based on the fields
    parquet_schema = pa.schema(fields)

    # Get each column's values converted to a pyarrow array
    pa_arrays = [pa.array(data[name]) for name in data.dtype.names]

    # Convert to pyarrow table for export, from these arrays
    pa_table = pa.Table.from_arrays(pa_arrays, schema=parquet_schema)

    # Save the data to a parquet file
    pq.write_table(pa_table, file_path)
    print(f"Saved data as parquet to {file_path}")

    return