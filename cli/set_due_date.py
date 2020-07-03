#!/usr/bin/env python3

from argparse import ArgumentParser
from datetime import datetime
from subprocess import call

def main(arguments):
    chore = arguments.chore.replace("'", "\'")
    due_date = arguments.due_date
    sql = f"CALL change_due_date('{chore}', '{due_date}', @c)"
    command = ["chore-database", sql]
    if arguments.preview:
        command.append("--preview")
    if arguments.verbose:
        command.append("--verbose")
    call(command)

def parse_arguments():
    parser = ArgumentParser(description="Change the due date of a chore.")
    parser.add_argument("chore", help="The chore whose due date to change.")
    date = lambda s: datetime.strptime(s, "%Y-%m-%d")
    parser.add_argument("due_date", type=date, help="The new due date.")
    parser.add_argument("--preview", action="store_true", help="Show the SQL command but do not execute it.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Show SQL commands as they are executed.")
    return parser.parse_args()

if __name__ == "__main__":
    arguments = parse_arguments()
    main(arguments)
