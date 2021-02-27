#!/bin/bash
echo "All commands are prefixed with \"chore-\".

READ COMMANDS
burndown
    Get a burndown report.
completions-needed
    Get the number of completions needed to achieve high confidence in the
    average chore duration.
get-completion-id
    Get the database identifier of the active completion of a chore.
history
    Show the history of a chory.
meals
    Show incomplete meal chores.
progress
    Shows progress made on overdue chores between two dates.
show-completion
    Show chore completion information.
today
    Show the number of minutes spent doing chores today.

SCHEDULE COMMANDS
change-due-date
    Change the due date of a chore.
delete
    Delete a chore completion.
hierarchize
    Hierarchize a chore completion to match the chore hierarchy.
postpone
    Postpone a chore a specified number of days.
schedule
    Create a new a chore to be due on a particular date.
schedule-meals
    Schedule all meal chores to be due on a particular date.
skip
    Skip doing a chore.

WRITE COMMANDS
create
    Create a new chore on a specified schedule.
complete
    Record that a chore is completed.
put-away-dishes
    Record how long it took to put away the dishes.
session
    Record that some time was spent working on a chore.
unknown-duration
    Record that was completed but it is not known how long it took."
