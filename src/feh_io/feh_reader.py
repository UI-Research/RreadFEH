"""
Class defining DYNASIM-FEH file reader.

DYNASIM FEH produces three files:

    - header file,
    - family file, and
    - person file.


read_feh and save_feh modules define functionality for accessing, processing, and writing files.
This module defines classes that can be used to edit those functionalities.
"""
from read_feh import read_feh_data_file
import os
import numpy as np

class FehReader:
    """
    Class to read a file in chunks, keeping track of the offset between calls.
    """
    def __init__(self, header_file:str, data_file:str, file_type:str, chunk_size:int=-1, var_list:list=None):
        # Initialize file held as empty. File is opened/closed when read is called.
        self.file = None
        self.file_size = os.path.getsize(data_file)
        self.data_file = data_file
        self.header_file = header_file
        self.file_type = file_type

        # Initialize chunk_size, bytes read, and var list
        self.chunk_size = chunk_size
        self.var_list = var_list
        self.bytes_read = 0

        # Check if file paths to headers and data exist, check file type initialization
        self.check_file_paths()
        self.check_file_type()

    # Check if file paths to headers and data exist
    def check_file_paths(self):
        if not os.path.exists(self.data_file):
            raise FileNotFoundError(f"File path for data is not correctly specified: {self.data_file}")
        elif not os.path.exists(self.header_file):
            raise FileNotFoundError(f"File path for header is not correctly specified: {self.data_file}")
    
    # Check if file type is correctly specified
    def check_file_type(self):
        if self.file_type not in ['person', 'family']:
            raise ValueError(f"Invalid file type: {self.file_type}." 
                             f"Must be input as '{'person'}' or '{'family'}'.")

    # Reset the data read in and the bytes read in
    def reset_data(self):
        self.file = None
        self.bytes_read = 0

    # Set chunk size, clear data read and reset cursor
    def set_chunk_size(self, chunk_size: int):
        self.chunk_size = chunk_size
        self.reset_data()
        
    # Set the var_list, clear data read and reset cursor
    def set_vars(self, var_list):
        if not isinstance(var_list, list):
            raise TypeError("Variables must be input as a list.")
        self.var_list = var_list
        self.reset_data()

    # If bytes read up to this point + new chunk size is greater than file size,
    # set chunk size to be the difference between file size and bytes read
    def check_chunk_size(self):
        if self.bytes_read + self.chunk_size > self.file_size:
            return self.file_size - self.bytes_read 
        else:
            return self.chunk_size
    
    # Read data file
    def read_chunk(self):
        # Need to set this so that we don't read past the end of the file
        reader_chunk_size = self.check_chunk_size()

        # Read in data file
        self.file = read_feh_data_file( header_file = self.header_file, 
                                        data_file = self.data_file,
                                        vars = self.var_list,
                                        file_type = self.file_type, 
                                        count = reader_chunk_size,
                                        offset = self.bytes_read)
        self.bytes_read += len(self.reader_chunk_size)
        
        return self.file