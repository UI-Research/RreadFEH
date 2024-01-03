
import re
import pandas as pd


def get_record_types(lines):
    
    scal_pat = '\s*V-\s+\w+\s+'
    arry_pat = '\s*V-\s+\S+\\('
    
    scalar_line_numbers = [i for i, line in enumerate(lines) if re.search(scal_pat, line)]
    array_line_numbers = [i for i, line in enumerate(lines) if re.search(arry_pat, line)]

    rec_type = [''] * len(lines)
    
    for index in scalar_line_numbers:
        rec_type[index] = 'scalar'
    for index in array_line_numbers:
        rec_type[index] = 'array'
    return rec_type


def parse_codebook_lines(lines):
    per_names = [re.sub(r'\s*V-\s*(\w+).*', r'\1', line).strip() for line in lines]
    rec_type = get_record_types(lines)  # Assuming get_record_types is defined elsewhere
    array_year_range = [re.sub(r'\s*V-\s*\w+\s+.*', '', line) for line in lines]
    array_year_range = [re.sub(r'\s*V-\s*\w+\((\d+\-\d+)\).*', r'\1', line) for line in array_year_range]
    array_year_start = [re.sub(r'(\d+)\-.*', r'\1', year_range).strip() for year_range in array_year_range]
    array_year_end = [re.sub(r'\d+\-(\d+).*', r'\1', year_range).strip() for year_range in array_year_range]
    
    return pd.DataFrame({'name': per_names, 'type': rec_type, 'start': array_year_start, 'end': array_year_end})


def parse_person_codebook(fname):

    with open(fname, 'r') as file:
        codebook_text = file.readlines()

    fam_rec_start = next(i for i, line in enumerate(codebook_text) if "RECORD- FAMILY" in line)
    per_rec_start = next(i for i, line in enumerate(codebook_text) if "RECORD- PERSON" in line)
    endvars = [i for i, line in enumerate(codebook_text) if "ENDVARS" in line]

    if not (endvars[0] > fam_rec_start and endvars[0] < per_rec_start and endvars[1] > per_rec_start):
        raise ValueError("ERROR: Codebook invalid")

    per_rec_lines = codebook_text[per_rec_start + 1:endvars[1]]
    per_rec_lines = [line for line in per_rec_lines if "V-" in line]

    return parse_codebook_lines(per_rec_lines)  # Assuming parse_codebook_lines is defined elsewhere

def df_to_col_names(df):
    rec_struct = df['name'].astype(str)
    
    arrays_df = df[df['type'] == 'array'][['name', 'start', 'end']]
    
    rec_struct = rec_struct.append(
        arrays_df.apply(
            lambda x: [x[0] + str(i) for i in range(int(x[1]), int(x[2]) + 1)],
            axis=1).explode(), 
        ignore_index=True)

    return rec_struct


def get_col_names(codebook):
    per_df = parse_person_codebook(codebook)
    col_names = df_to_col_names(per_df)
    return col_names

if __name__ == '__main__':

    fname = 'codebook_2087ds.sipp2006'

    df = get_col_names(fname)

    print(df)