#!/usr/bin/env python3

from argparse import ArgumentParser
from subprocess import call
from sys import argv

def main(arguments):
    sql = "SELECT * FROM skippable_chores"
    command = ["chore-database", sql, "--column-names", "--silent=false"]
    command.extend(argv[1:])
    call(command)

def parse_arguments():
    parser = ArgumentParser(description="Show overdue chores that should be skipped.")
    parser.add_argument("--preview", action="store_true", help="Show the SQL command but do not execute it.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Show SQL commands as they are executed.")
    return parser.parse_args()

if __name__ == "__main__":
    arguments = parse_arguments()
    main(arguments)
