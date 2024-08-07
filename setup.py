"""
Setup file to instantiate installation of package from command line.

Update file with new version every time it is updated:
- version="1.0.0" -> version="1.0.1" for a small change that patches bugs that do not alter compatability
- version="1.0.0" -> version="1.1.0" for a minor change that adds new features but does not break compatability
- version="1.0.0" -> version="2.0.0" for a major change that breaks compatability with the previous version
"""
from setuptools import setup, find_packages

setup(
    name="feh_io",
    version="1.0.0",
    packages=find_packages(),
)