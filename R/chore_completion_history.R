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

plot.completion.rate <- function (data, chore.name) {
  ggplot(data, aes(x = due_date, y = num_completed)) +
    geom_point() +
    geom_ma(ma_fun = SMA, n = 7) +
    ggtitle(paste("Completion rate of", chore.name)) +
    xlab("Due date") +
    ylab("0 = incomplete, 1 = complete")
}

main <- function (chore.name = NULL) {
  if (length(chore.name) > 1) {
    stop("Too many arguments\nUsage: chore-completion-history CHORE_NAME")
  }
  chore.completion.history <- using.database(function (fetch.query.results) {
    query.chore.completion.history(fetch.query.results, chore.name)
  })
  plot.completion.rate(chore.completion.history, chore.name)
}

if (!interactive() & basename(sys.frame(1)$ofile) == "chore_completion_history.R") {
  main(argv)
}
