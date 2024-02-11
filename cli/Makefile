all: list-commands burndown change-due-date complete completions-needed create \
	database delete get-completion-id hierarchize history meals postpone \
	progress put-away-dishes schedule schedule-meals session show-completion \
	skip skippable today unknown-duration
clean:
	$(RM) -r *.pyc bin
install:
	cp bin/* ~/.local/bin
	cp chore-aliases.sh ~/.chore_aliases
	./install-cnf.sh
bin:
	mkdir bin
# Copy scripts to installation names
list-commands: bin list-commands.sh
	cp list-commands.sh bin/chore
burndown: bin burndown.sh
	cp burndown.sh bin/chore-burndown
change-due-date: bin set_due_date.py
	cp set_due_date.py bin/chore-change-due-date
complete: bin complete-chore.sh
	cp complete-chore.sh bin/chore-complete
completions-needed: bin show_completions_needed.py
	cp show_completions_needed.py bin/chore-completions-needed
create: bin create_chore.py
	cp create_chore.py bin/chore-create
database: bin database.sh
	cp database.sh bin/chore-database
delete: bin delete-chore.sh
	cp delete-chore.sh bin/chore-delete
get-completion-id: bin get-chore-completion-id.sh
	cp get-chore-completion-id.sh bin/chore-get-completion-id
hierarchize: bin hierarchize-chore-completion.sh
	cp hierarchize-chore-completion.sh bin/chore-hierarchize
history: bin chore-history.sh
	cp chore-history.sh bin/chore-history
meals: bin show-meal-chores.sh
	cp show-meal-chores.sh bin/chore-meals
postpone: bin postpone_chore.py
	cp postpone_chore.py bin/chore-postpone
progress: bin completed-and-remaining.sh
	cp completed-and-remaining.sh bin/chore-progress
put-away-dishes: bin put-away-dishes.sh
	cp put-away-dishes.sh bin/chore-put-away-dishes
schedule: bin schedule-chore.sh
	cp schedule-chore.sh bin/chore-schedule
schedule-meals: bin schedule-meals.sh
	cp schedule-meals.sh bin/chore-schedule-meals
session: bin complete-chore-session.sh
	cp complete-chore-session.sh bin/chore-session
show-completion: bin show-chore-completion.sh
	cp show-chore-completion.sh bin/chore-show-completion
skip: bin skip-chore.sh
	cp skip-chore.sh bin/chore-skip
skippable: bin skippable_chores.py
	cp skippable_chores.py bin/chore-skippable
today: bin chore-duration-today.sh
	cp chore-duration-today.sh bin/chore-today
unknown-duration: bin complete-chore-unknown-duration.sh
	cp complete-chore-unknown-duration.sh bin/chore-unknown-duration
