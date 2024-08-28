"""
Class defining DYNASIM-FEH file reader.

DYNASIM FEH produces three files:

    - header file,
    - family file, and
    - person file.


read_feh and save_feh modules define functionality for accessing, processing, and writing files.
This module defines classes that can be used to edit those functionalities.
"""

import struct
import numpy as np
import io
import os
import numpy.lib.recfunctions as rf
import pyarrow.parquet as pq # for parquet file format
import pyarrow as pa # for pyarrow functions format
import pandas as pd

class FehReader:
    """
    original suggestion
    """
    def __init__(self, filename, chunksize=-1, varlist=None):
        self.bytes_read=0
        self.file = open(filename)
        self.file_size = os.path.getsize(filename)

    def read(self):
        data = self.file.read(chunksize)
        self.bytes_read = self.bytes_read + len(data)
        if self.bytes_read >= self.file_size:
            self.file(close)
        return data

class FehReader:
    """
    Class to read a file in chunks, keeping track of the offset between calls.
    """
    def __init__(self, filename, chunksize=-1, varlist=None):
        self.filename = filename
        self.chunksize = chunksize
        self.varlist = varlist
        self.bytes_read = 0
        self.file_size = os.path.getsize(filename)
        try:
            self.file = open(filename, 'rb')
        except IOError as e:
            print(f"Error opening file: {e}")
            self.file = None

    def read(self):
        if self.file is None:
            print("File is not open.")
            return None
        
        if self.chunksize == -1:
            self.chunksize = self.file_size
        
        data = self.file.read(self.chunksize)
        self.bytes_read += len(data)
        
        if self.bytes_read >= self.file_size:
            self.file.close()
        
        return data

    def __del__(self):
        if self.file and not self.file.closed:
            self.file.close()