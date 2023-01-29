source("database.R")

query.chore.completion.history <- function (fetch.query.results, chore.name) {
  "SELECT DATE(due_date) AS due_date, SUM(is_complete) AS num_completed
      FROM chore_completions
      JOIN chores USING (chore_id)
      JOIN chore_completion_statuses USING (chore_completion_status_id)
      JOIN chore_schedule USING (chore_completion_id)
      WHERE chore = ?
          AND due_date BETWEEN DATE_ADD(NOW(), INTERVAL -30 DAY) AND DATE(NOW())
      GROUP BY DATE(due_date)
      ORDER BY due_date" %>%
  fetch.query.results(list(chore.name))
}

main <- function (chore.name = NULL) {
  if (length(chore.name) > 1) {
    stop("Too many arguments\nUsage: chore-completion-history CHORE_NAME")
  }
  chore.completion.history <- using.database(function (fetch.query.results) {
    query.chore.completion.history(fetch.query.results, chore.name)
  })
  chore.completion.history
}

if (!interactive() & basename(sys.frame(1)$ofile) == "chore_completion_history.R") {
  main(argv)
}
