"""
Test for DYNASIM FEH package.

This script tests the DYNASIM feh_io module.
"""

from feh_io.read_feh.read_feh import read_feh_data_file, read_parquet_2
from feh_io.save_feh.save_feh import save_feh_parquet

def test_read_feh_data_file(header_file, data_file, file_type, vars=None):
    """
    Unit test for reading FEH data files. Pauses between each output for observation.

    Args:
    header_file (str): The path to the header file.
    data_file (str): The path to the data file.
    file_type (str): The type of file being tested ('person' or 'family').
    vars (list, optional): List of variables to subset. Defaults to None.
    """

    # Test the read function with the provided file type and vars
    data_out = read_feh_data_file(header_file, data_file, vars=vars,
                                         file_type=file_type, count=1)
    
    # Describe case
    print(f'Test: {file_type}-level records from {data_file} with vars={vars}')
    # Print column names
    print(data_out.dtype.names)
    # Print first record
    print(data_out)
    input("Press Enter to continue...\n\n")  # Pause here
    
    return data_out

def test_read_parquet_data_file(file_path:str, file_type:str, sample_type:str):
    """
    Args:
        file_path (str): path to read the data from parquet. 
        file_type (str): type of file being read ('person' or 'family').
        sample_type (str): type of sample being read ('input' or 'output').

    Returns:
        structured numpy array: data 
    """
    # Test the read function with the provided file type and vars
    data_out = read_parquet_2(file_path)
    
    # Describe case
    print(f'Test: records from {file_path} for {file_type}-type {sample_type} records')
    # Print first record
    print(data_out)
    input("Press Enter to continue...\n\n")  # Pause here
    
    return data_out

if __name__ == '__main__':

    # Test output files
    out_header_file = 'data/output/run-1006-baseline/base-v8/dynasipp_header_even.dat'
    out_person_file = 'data/output/run-1006-baseline/base-v8/dynasipp_person_even.dat'
    out_family_file = 'data/output/run-1006-baseline/base-v8/dynasipp_family_even.dat'

    # Test input files
    in_header_file = 'data/starting-sample/v2/dynasipp_HEADER.dat'
    in_person_file = 'data/starting-sample/v2/dynasipp_PERSON.dat'
    in_family_file = 'data/starting-sample/v2/dynasipp_FAMILY.dat'

    print('TEST I/O FILES WITHOUT SUBSETTING')

    # Test the read function for people and families, input and output
    data_person_out = test_read_feh_data_file(out_header_file, out_person_file, vars = None, file_type='person')
    data_fam_out = test_read_feh_data_file(out_header_file, out_family_file, vars = None, file_type='family')
    data_person_in = test_read_feh_data_file(in_header_file, in_person_file, vars = None, file_type='person')
    data_fam_in = test_read_feh_data_file(in_header_file, in_family_file, vars = None, file_type='family')

    print('TEST I/O FILES WITH SUBSETTING')

    # Test the read function for people and families, input and output (with vars subset)
    data_person_out_subset = test_read_feh_data_file(out_header_file, out_person_file, vars = ['SEGTYPE','ETHNCTY'], file_type='person')
    data_fam_out_subset = test_read_feh_data_file(out_header_file, out_family_file, vars = ['SEGTYPE','MEMBERS'], file_type='family')
    data_person_in_subset = test_read_feh_data_file(in_header_file, in_person_file, vars = ['SEGTYPE','ETHNCTY'], file_type='person')
    data_fam_in_subset = test_read_feh_data_file(in_header_file, in_family_file, vars = ['SEGTYPE','MEMBERS'], file_type='family')

    print('TEST SAVE FUNCTIONS')

    # Test the save function for files to parquet format
    output_path = 'data/output/run-1006-baseline/base-v8/'
    save_feh_parquet(data_person_out, output_path, filename='person_out')
    output_path = 'data/starting-sample/v2/'
    save_feh_parquet(data_person_in, output_path, filename='person_in')

    # If we read back in, do these files match?
    in_person_file = 'data/starting-sample/v2/person_in.parquet'
    out_person_file = 'data/output/run-1006-baseline/base-v8/person_out.parquet'
    data_person_in_post_io = test_read_parquet_data_file(in_person_file, file_type='person', sample_type = 'input')
    data_person_out_post_io = test_read_parquet_data_file(out_person_file, file_type='person', sample_type = 'output')

    print(f'Do the original input person files match what is output by this package? {data_person_in_post_io == data_person_in}')
    print(f'Do the original output person files match what is output by this package? {data_person_out_post_io == data_person_out}')


    


    






    