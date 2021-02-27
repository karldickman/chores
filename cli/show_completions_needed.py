#!/usr/bin/env python3

from argparse import ArgumentParser
from subprocess import call

def main(arguments):
    chore = arguments.chore.replace("'", "\'")
    sql = f"CALL show_chore_completions_needed('{chore}')"
    command = ["chore-database", sql, "--column-names", "--silent=false"]
    if arguments.preview:
        command.append("--preview")
    if arguments.verbose:
        command.append("--verbose")
    call(command)

def parse_arguments():
    parser = ArgumentParser(description="Get the number of completions needed to achieve high confidence in the average chore duration.")
    parser.add_argument("chore", help="The chore whose needed completions to calculate.")
    parser.add_argument("--preview", action="store_true", help="Show the SQL command but do not execute it.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Show SQL commands as they are executed.")
    return parser.parse_args()

if __name__ == "__main__":
    arguments = parse_arguments()
    main(arguments)
