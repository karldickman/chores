#!/usr/bin/env python3

from argparse import ArgumentParser
from subprocess import call

def main(arguments):
    date = arguments.date
    date = f"'{date}'" if date is not None else "NULL"
    sql = f"CALL skippable_chores_pretty({date})"
    command = ["chore-database", sql, "--column-names", "--silent=false"]
    if arguments.preview:
        command.append("--preview")
    if arguments.verbose:
        command.append("--verbose")
    call(command)

def parse_arguments():
    parser = ArgumentParser(description="Show overdue chores that should be skipped.")
    parser.add_argument("--date", help="The date as of which to show skippable chores.")
    parser.add_argument("--preview", action="store_true", help="Show the SQL command but do not execute it.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Show SQL commands as they are executed.")
    return parser.parse_args()

if __name__ == "__main__":
    arguments = parse_arguments()
    main(arguments)
