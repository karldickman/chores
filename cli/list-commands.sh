#!/bin/bash
echo "All commands are prefixed with \"chore-\".

READ COMMANDS
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
delete
    Delete a chore completion.
hierarchize
    Hierarchize a chore completion to match the chore hierarchy.
schedule
    Schedule a chore to be due on a particular date.
skip
    Skip doing a chore.

WRITE COMMANDS
complete
    Record that a chore is completed.
put-away-dishes
    Record how long it took to put away the dishes.
session
    Record that some time was spent working on a chore.
unknown-duration
    Record that was completed but it is not known how long it took."
