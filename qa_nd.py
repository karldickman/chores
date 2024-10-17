#!/usr/bin/env python

from datetime import datetime

from cli.complete_overdue_chores import database

def main():
    with database() as cnx:
        with cnx.cursor() as cursor:
            cursor.execute("SELECT chore_completion_id, next_due_date FROM chore_completion_next_due_dates")
            next_due_dates: "list[tuple[int, datetime]]" = cursor.fetchall()
            for chore_completion_id, next_due_date in next_due_dates:
                cursor.execute("SELECT chore_completion_next_due_date(%s)", [chore_completion_id])
                alternative_calc: datetime = cursor.fetchone()[0]
                if next_due_date is None and alternative_calc is None:
                    continue
                if abs((next_due_date - alternative_calc).days) > 1:
                    print(chore_completion_id, next_due_date, alternative_calc)

if __name__ == "__main__":
    main()