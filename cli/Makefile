all: list-commands burndown complete database delete get-completion-id hierarchize history meals postpone progress put-away-dishes schedule session show-completion skip skippable today unknown-duration
clean:
	rm *.pyc chore chore-burndown chore-complete chore-database chore-delete chore-get-completion-id chore-hierarchize chore-history chore-meals chore-postpone chore-progress chore-put-away-dishes chore-schedule chore-session chore-show-completion chore-skip chore-skippable chore-today chore-unknown-duration
install:
	cp chore chore-burndown chore-complete chore-database chore-delete chore-get-completion-id chore-hierarchize chore-history chore-meals chore-postpone chore-progress chore-put-away-dishes chore-schedule chore-session chore-show-completion chore-skip chore-skippable chore-today chore-unknown-duration ~/.local/bin
# Copy scripts to installation names
list-commands:
	cp list-commands.sh chore
burndown:
	cp burndown.sh chore-burndown
complete:
	cp complete-chore.sh chore-complete
database:
	cp database.sh chore-database
delete:
	cp delete-chore.sh chore-delete
get-completion-id:
	cp get-chore-completion-id.sh chore-get-completion-id
hierarchize:
	cp hierarchize-chore-completion.sh chore-hierarchize
history:
	cp chore-history.sh chore-history
meals:
	cp show-meal-chores.sh chore-meals
postpone:
	cp postpone_chore.py chore-postpone
progress:
	cp completed-and-remaining.sh chore-progress
put-away-dishes:
	cp put-away-dishes.sh chore-put-away-dishes
schedule:
	cp schedule-chore.sh chore-schedule
session:
	cp complete-chore-session.sh chore-session
show-completion:
	cp show-chore-completion.sh chore-show-completion
skip:
	cp skip-chore.sh chore-skip
skippable:
	cp skippable_chores.py chore-skippable
today:
	cp chore-duration-today.sh chore-today
unknown-duration:
	cp complete-chore-unknown-duration.sh chore-unknown-duration
