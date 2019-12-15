#!/usr/bin/env python3

from argparse import ArgumentParser
from subprocess import call

def main(arguments):
    chore = arguments.chore.replace("'", "\'")
    days = arguments.days
    sql = "CALL postpone_chore('{}', {}, @c)".format(chore, days)
    command = ["chore-database", sql]
    if arguments.preview:
        command.append("--preview")
    if arguments.verbose:
        command.append("--verbose")
    call(command)

def parse_arguments():
    parser = ArgumentParser(description="Postpone a chore for a specified number of days.")
    parser.add_argument("chore", help="The chore to postpone.")
    parser.add_argument("days", type=float, help="The number of days to postpone the chore.")
    parser.add_argument("--preview", action="store_true", help="Show the SQL command but do not execute it.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Show SQL commands as they are executed.")
    return parser.parse_args()

if __name__ == "__main__":
    arguments = parse_arguments()
    main(arguments)
