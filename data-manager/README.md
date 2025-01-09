# Overview
This directory contains basic API functionality for the Dynasim data manager in Python and R.

Users can import these files and call functions to interact with the API. You can view sample Python calls in python_src/python-sample-calls.ipynb and sample R calls in R-example-calls.Rmd.

## Testing
First set up an .env file in data-manater/ with your credentials

```
TEST_EMAIL=email@email.org
TEST_PASSWORD=password123
```

From data-manager/ directory, run `pytest tests/tests.py`