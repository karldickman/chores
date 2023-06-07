#!/usr/bin/env r

suppressPackageStartupMessages(library(ggplot2))
suppressPackageStartupMessages(library(tidyquant))

source("database.R")

query.chore.completion.history <- function (fetch.query.results, chore.names) {
  chore.params <- paste(rep("?", length(chore.names)), collapse = ", ")
  arguments <- append(as.list(chore.names), 90)
  paste0("WITH due_dates_and_completion_times AS (SELECT due_date
    	    , when_completed
          , CASE WHEN when_completed < due_date
        			THEN when_completed
                  ELSE due_date
              END AS `date`
          , is_complete
      FROM chore_completions
      JOIN chores USING (chore_id)
      JOIN chore_completion_statuses USING (chore_completion_status_id)
      JOIN chore_schedule USING (chore_completion_id)
      LEFT JOIN chore_completions_when_completed USING (chore_completion_id)
      WHERE chore IN (", chore.params, ")
          AND due_date BETWEEN DATE_ADD(NOW(), INTERVAL -? DAY) AND DATE(NOW()))
  SELECT DATE(`date`) AS `date`, SUM(is_complete) AS num_completed
    	FROM due_dates_and_completion_times
      GROUP BY DATE(`date`)
      ORDER BY `date`") %>%
  fetch.query.results(arguments)
}

plot.completion.rate <- function (data, chore.names) {
  if (length(chore.names) == 1) {
    chore.name = chore.names
  } else {
    chore.name = paste(length(chore.names), "chores")
  }
  ggplot(data, aes(x = date, y = num_completed)) +
    geom_point() +
    geom_ma(ma_fun = SMA, n = 7) +
    ggtitle(paste("Completion rate of", chore.name)) +
    xlab("Due date") +
    ylab("Times completed per due date")
}

main <- function (chore.names) {
  if (is.null(chore.names)) {
    stop("Missing argument\nUsage: chore-completion-history CHORE_NAME [CHORE_NAME ...]")
  }
  chore.completion.history <- using.database(function (fetch.query.results) {
    query.chore.completion.history(fetch.query.results, chore.names)
  })
  plot.completion.rate(chore.completion.history, chore.names)
}

if (!interactive() & basename(sys.frame(1)$ofile) == "chore_completion_history.R") {
  main(argv)
}
