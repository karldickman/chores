#!/usr/bin/env python

"Expand an abbreviated date into an ISO 8601 date."

from argparse import ArgumentParser
from datetime import date, datetime
import re

def is_potentially_valid(date_string):
    "Checks whether a date string is potentially a valid date."
    return re.match("^([0-9]{4}[-/])?((1[0-9])|(0?[1-9]))[-/]((3[01])|([12][0-9])|(0?[1-9]))$", date_string)

def expand_date(date_string):
    "Expands an abbreviated date into an ISO 8601 date."
    if not is_potentially_valid(date_string):
        raise ValueError("Invalid date \"%s\".", date_string)
    components = date_string.split("-")
    if len(components) == 1:
        components = date_string.split("/")
    if len(components) not in (2, 3):
        raise ValueError("Invalid date \"%s\".", date_string)
    if len(components) == 2:
        year = datetime.today().year
        month, day = map(int, components)
    else:
        year, month, day = map(int, components)
    return date(year, month, day)

def main():
    "Parse command-line arguments and execute."
    parser = ArgumentParser(description=__doc__)
    parser.add_argument("date", help="Date string to expand into an ISO 8601 date.")
    arguments = parser.parse_args()
    expanded_date = expand_date(arguments.date)
    print expanded_date

if __name__ == "__main__":
    main()
