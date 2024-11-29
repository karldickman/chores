#!/usr/bin/env python

from argparse import ArgumentParser
from configparser import ConfigParser
from datetime import datetime
from os.path import expanduser

import mysql.connector

def parse_arguments():
    parser = ArgumentParser(description="Complete all overdue chores on the specified date.")
    parser.add_argument("date", type = lambda d: datetime.strptime(d, "%Y-%m-%d").date(), help = "The date on which to complet the overdue chores.")
    return parser.parse_args()

def config(filename: str = "~/.my.cnf", section: str = "clientchores") -> "dict[str, str]":
    filename = expanduser(filename)
    parser = ConfigParser()
    parser.read(filename)
    db_config: "dict[str, str]" = {}
    if parser.has_section(section):
        params = parser.items(section)
        for param in params:
            key, value = param
            db_config[key] = str(value)
        return db_config
    else:
        raise Exception(f"Section {section} not found in the {filename} file.")

def database():
    db_config = config()
    return mysql.connector.connect(**db_config)

def main():
    args = parse_arguments()
    cnx = database()
    with cnx.cursor() as cursor:
        cursor.execute("""
            SELECT chore, overdue_chore_completion_status_id
            FROM chore_completion_overdue_statuses
            WHERE due_date < DATE_ADD(%s, INTERVAL 1 DAY)
                AND (DATE(next_due_date) <= DATE_ADD(%s, INTERVAL 1 DAY)
					OR schedule_from_id = 2) -- due date
                AND overdue_chore_completion_status_id IS NOT NULL
            ORDER BY overdue_chore_completion_status DESC, next_due_date, due_date;
        """, [args.date, args.date])
        overdue_chores = cursor.fetchall()
    for chore in overdue_chores:
        chore_name, status_id = chore
        if status_id == 2:
            print(f"CALL skip_chore('{chore_name}', @c, @n);")
        elif status_id == 3:
            print(f"CALL complete_chore_without_data('{chore_name}', NULL, @c, @n);")
        else:
            print("/* Skipping", chore_name, "unknown status_id", status_id, "*/")

if __name__ == "__main__":
    main()