all: list-commands burndown complete create database delete get-completion-id \
	hierarchize history meals postpone progress put-away-dishes schedule \
	schedule-meals session show-completion skip skippable today unknown-duration
clean:
	$(RM) *.pyc chore chore-burndown chore-complete chore-create chore-database chore-delete \
	chore-get-completion-id chore-hierarchize chore-history chore-meals \
	chore-postpone chore-progress chore-put-away-dishes chore-schedule \
	chore-schedule-meals chore-session chore-show-completion chore-skip \
	chore-skippable chore-today chore-unknown-duration
install:
	cp chore chore-burndown chore-complete chore-create chore-database chore-delete \
	chore-get-completion-id chore-hierarchize chore-history chore-meals \
	chore-postpone chore-progress chore-put-away-dishes chore-schedule \
	chore-schedule-meals chore-session chore-show-completion chore-skip \
	chore-skippable chore-today chore-unknown-duration ~/.local/bin
# Copy scripts to installation names
list-commands: list-commands.sh
	cp list-commands.sh chore
burndown: burndown.sh
	cp burndown.sh chore-burndown
complete: complete-chore.sh
	cp complete-chore.sh chore-complete
create: create_chore.py
	cp create_chore.py chore-create
database: database.sh
	cp database.sh chore-database
delete: delete-chore.sh
	cp delete-chore.sh chore-delete
get-completion-id: get-chore-completion-id.sh
	cp get-chore-completion-id.sh chore-get-completion-id
hierarchize: hierarchize-chore-completion.sh
	cp hierarchize-chore-completion.sh chore-hierarchize
history: chore-history.sh
	cp chore-history.sh chore-history
meals: show-meal-chores.sh
	cp show-meal-chores.sh chore-meals
postpone: postpone_chore.py
	cp postpone_chore.py chore-postpone
progress: completed-and-remaining.sh
	cp completed-and-remaining.sh chore-progress
put-away-dishes: put-away-dishes.sh
	cp put-away-dishes.sh chore-put-away-dishes
schedule: schedule-chore.sh
	cp schedule-chore.sh chore-schedule
schedule-meals: schedule-meals.sh
	cp schedule-meals.sh chore-schedule-meals
session: complete-chore-session.sh
	cp complete-chore-session.sh chore-session
show-completion: show-chore-completion.sh
	cp show-chore-completion.sh chore-show-completion
skip: skip-chore.sh
	cp skip-chore.sh chore-skip
skippable: skippable_chores.py
	cp skippable_chores.py chore-skippable
today: chore-duration-today.sh
	cp chore-duration-today.sh chore-today
unknown-duration: complete-chore-unknown-duration.sh
	cp complete-chore-unknown-duration.sh chore-unknown-duration
