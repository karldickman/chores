#!/usr/bin/env python3

from argparse import ArgumentParser
from subprocess import call

def main(arguments):
    chore = arguments.chore.replace("'", "\'")
    completions_per_day = arguments.completions_per_day
    aggregate_by_id = { "empty": 0, "weekendity": 2 }[arguments.aggregate_by]
    frequency_days = arguments.days if arguments.days is not None else "NULL"
    sql = f"CALL create_chore('{chore}', {aggregate_by_id}, {completions_per_day}, {frequency_days}, @c);"
    command = ["chore-database", sql]
    if arguments.preview:
        command.append("--preview")
    if arguments.verbose:
        command.append("--verbose")
    call(command)

def parse_arguments():
    parser = ArgumentParser(description="Create a chore at the specified frequency.")
    parser.add_argument("chore", help="The name of the chore to create.")
    parser.add_argument("--aggregate-by", default="empty", help="The key on which to aggregate chore durations.")
    parser.add_argument("--completions-per-day", type=int, default=1, help="The number of completions to allow per day.")
    parser.add_argument("--days", type=float, help="The frequency of the chore in days.")
    parser.add_argument("--preview", action="store_true", help="Show the SQL command but do not execute it.")
    parser.add_argument("-v", "--verbose", action="store_true", help="Show SQL commands as they are executed.")
    return parser.parse_args()

if __name__ == "__main__":
    arguments = parse_arguments()
    main(arguments)
