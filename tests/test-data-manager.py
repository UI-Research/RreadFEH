# To run, from data-manager, use `pytest tests/test-data-manager.py`
# To see print output and verbose output, use `pytest tests/test-data-manager.py -sv`

import pytest
from src.feh_io import DataManager
import os
from dotenv import load_dotenv
import pandas as pd
import logging

load_dotenv()

# create directory to store data
os.makedirs(f"{os.getcwd()}/tests/tmp/", exist_ok=True)

dm = DataManager()
TEST_EMAIL = os.getenv('TEST_EMAIL')
TEST_PASSWORD = os.getenv('TEST_PASSWORD')

try:
    dm.connect(TEST_EMAIL, TEST_PASSWORD)
except Exception as e:
    raise e

project_name = "BabyBonds"
scenarios = ["Baseline_v1", "BabyBonds_v1"]
family_variables = ["fam_id", "fam_size", "immigration_year"]
person_variables = ["earnings", "health_status", "leave_year"]

birth_year_range = [1981, 2018]
year_range = [1974, 2050]

paths = ["./tests/tmp/family_data.pq", "./tests/tmp/person_data.pq"]


def download_no_filter():

    try:
        dm.get_dataset(
            output_dir="./tests/tmp/",
            file_type="parquet",
            project_name=project_name,
            scenarios=scenarios,
            family_variables=family_variables,
            person_variables=person_variables
        )
    except Exception as e:
        raise e

    paths = ["./tests/tmp/family_data.pq", "./tests/tmp/person_data.pq"]
    for path in paths:
        if os.path.exists(path):
            new_name = path.split("_")
            new_name = new_name[0] + "_no_filter.pq"
            os.rename(path, new_name)

    return True

def download_birth_year_filter():
    try:
        dm.get_dataset(
            output_dir="./tests/tmp/",
            file_type="parquet",
            project_name=project_name,
            scenarios=scenarios,
            family_variables=family_variables,
            person_variables=person_variables,
            birth_year_range=birth_year_range
        )
    except Exception as e:
        raise e

    for path in paths:
        if os.path.exists(path):
            new_name = path.split("_")
            new_name = new_name[0] + "_birth_year_filter.pq"
            os.rename(path, new_name)

    return True

def download_year_filter():
    try:
        dm.get_dataset(
            output_dir="./tests/tmp/",
            file_type="parquet",
            project_name=project_name,
            scenarios=scenarios,
            family_variables=family_variables,
            person_variables=person_variables,
            year_range=year_range
        )
    except Exception as e:
        raise e

    for path in paths:
        if os.path.exists(path):
            new_name = path.split("_")
            new_name = new_name[0] + "_year_filter.pq"
            os.rename(path, new_name)
    return True

def test_downloads():
    assert download_no_filter()
    assert download_birth_year_filter()
    assert download_year_filter()

@pytest.fixture
def birth_year_dfs():
    fby = pd.read_parquet("./tests/tmp/family_birth_year_filter.pq")
    pby = pd.read_parquet("./tests/tmp/person_birth_year_filter.pq")

    return fby, pby

@pytest.fixture
def year_dfs():
    fy = pd.read_parquet("./tests/tmp/family_year_filter.pq")
    py = pd.read_parquet("./tests/tmp/person_year_filter.pq")

    return fy, py
    
@pytest.fixture
def dfs():
    family_df = pd.read_parquet("./tests/tmp/family_no_filter.pq")
    person_df = pd.read_parquet("./tests/tmp/person_no_filter.pq")

    return family_df, person_df

def test_dfs(dfs):
    family_df, person_df = dfs
    
    # check scenarios
    assert set(family_df['scenario_name'].unique()) == set(scenarios)
    assert set(person_df['scenario_name'].unique()) == set(scenarios)

    # check cols
    # these vars have year dimensions: earnings (1951-2100), health_status (2006-2100)
    # make sure the columns are correct
    # last column is always scenario name
    assert len(family_df.columns) == len(family_variables) + 1
    assert len(person_df.columns) == 1 + (2100-1951+1) + (2100-2006+1) + 1

def test_birth_year_range(dfs, birth_year_dfs):
    family_df, person_df = dfs
    fby, pby = birth_year_dfs

    # birth year filtering means fewer rows
    # birth_year_range = [1981, 2018]

    assert len(fby) <= len(family_df)
    assert len(pby) <= len(person_df)

    assert pby['birth_year'].min() == birth_year_range[0]
    assert pby['birth_year'].max() == birth_year_range[1]


def test_year_range(dfs, year_dfs):
    family_df, person_df = dfs
    fy, py = year_dfs

    assert len(family_df.columns) >= len(fy.columns)
    assert len(person_df.columns) >= len(py.columns)

    # these vars have year dimensions: earnings (1951-2100), health_status (2006-2100)
    # make sure the columns are correct
    # last column is always scenario name
    assert len(fy.columns) == len(family_variables) + 1
    assert len(py.columns) == 1 + (min(2100, year_range[1])-max(1951, year_range[0])+1) + (min(2100, year_range[1])-max(2006, year_range[0])+1) + 1

    # check that non var_dim vars are the same
    assert person_df['leave_year'].sum() == py['leave_year'].sum()

