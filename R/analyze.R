library(data.table)
library(dplyr)

source("database.R")
source("log_normal.R")

chore.breakdown.chart <- function (fitted.chore.durations, title) {
  durations <- fitted.chore.durations %>%
    expand.many.chore.completions.per.day %>%
    scale.less.than.one.chore.completion.per.day %>%
    arrange(-median_duration_minutes) # Sort in descending order of median duration
  # Calculate key values
  mode <- durations$mode_duration_minutes
  median <- durations$median_duration_minutes - durations$mode_duration_minutes
  mean <- durations$mean_duration_minutes - durations$median_duration_minutes
  q.95 <- qlnorm(0.95, durations$mean_log_duration_minutes, durations$sd_log_duration_minutes) -
    durations$mean_duration_minutes
  # Transpose data frame for presentation in stacked bar chart
  summary.values<- data.frame(mode, median, mean, q.95) %>% transpose
  colnames(summary.values) <- durations$chore
  rownames(summary.values) <- c("mode", "median", "mean", "95%ile")
  # Create stacked bar chart
  summary.values %>% as.matrix %>%
    barplot(main = title, ylab = "Duration (minutes)", las = 2)
}

chore.histogram <- function (chore.name, duration.minutes, mean.log, sd.log, mode, left.tail = 0.0001, right.tail = 0.995) {
  title <- paste("Histogram of", chore.name, "duration")
  xlab <- paste(chore.name, "duration (minutes)")
  if (is.na(sd.log)) {
    cat("Insufficient to fit distribution for", chore.name, "\n")
    tryCatch({
        hist(duration.minutes, main = title, xlab = xlab, freq=FALSE)
      },
      error=function (error) {
        cat("Cannot plot", chore.name, "\n")
      },
      warning=function (warning) {
        cat("Cannot plot", chore.name, "\n")
      }
    )
    return()
  }
  histogram <- hist(duration.minutes, plot = FALSE)
  breaks <- histogram$breaks
  xmin <- min(c(qlnorm(left.tail, mean.log, sd.log), breaks))
  xmax <- max(c(qlnorm(right.tail, mean.log, sd.log), breaks))
  x <- seq(0, xmax, 0.01)
  y <- dlnorm(x, mean.log, sd.log)
  fit.max.density <- dlnorm(mode, mean.log, sd.log)
  ymax <- max(c(fit.max.density, histogram$density))
  hist(duration.minutes, main = title, xlab = xlab, freq =FALSE, xlim = c(xmin, xmax), ylim = c(0, ymax))
  lines(x, y)
}

chore.histograms <- function (chore.durations, fitted.chore.durations) {
  for(i in 1:nrow(fitted.chore.durations)) {
    chore.data <- fitted.chore.durations[i,]
    chore.name <- chore.data$chore
    aggregate.by <- chore.data$aggregate_by_id
    chore.completions <- subset(chore.durations, chore == chore.name)
    if (aggregate.by == 2) {
      aggregate.key <- chore.data$aggregate_key
      chore.completions <- subset(chore.completions, weekendity == aggregate.key)
      chore.name <- paste(ifelse(aggregate.key == 0, "weekday", "weekend"), chore.name)
    }
    mean.log <- chore.data$mean_log_duration_minutes
    sd.log <- chore.data$sd_log_duration_minutes
    mode <- chore.data$mode_duration_minutes
    chore.histogram(chore.name, chore.completions$duration_minutes, mean.log, sd.log, mode)
  }
}

expand.many.chore.completions.per.day <- function (fitted.chore.durations) {
  # Split up many per day and at most once per day because they need to be dealt with separately
  many.per.day <- subset(fitted.chore.durations, completions_per_day > 1)
  one.or.fewer.per.day <- subset(fitted.chore.durations, completions_per_day <= 1)
  # Repeat chores completed more than once per day
  repeated.chores <- c()
  for (i in 1:nrow(many.per.day)) {
    chore.data <- many.per.day[i,]
    chore.name <- chore.data$chore
    completions.per.day <- chore.data$completions_per_day
    for (. in 1:completions.per.day) {
      repeated.chores <- c(repeated.chores, chore.name)
    }
    if (abs(completions.per.day - round(completions.per.day)) > 0.1) {
      cat(chore.name, "has non-integer completions per day", completions.per.day, "\n")
    }
  }
  # Expand each instance by merging on repeated chores vector
  many.per.day <- merge(many.per.day, data.frame(chore = repeated.chores))
  # Update to once per day as this is now represented through repetition
  many.per.day$completions_per_day <- 1
  # Recombine with chores that have 1 or fewer completions per day
  rbind(many.per.day, one.or.fewer.per.day)
}

scale.less.than.one.chore.completion.per.day <- function (fitted.chore.durations) {
  # Split up less than and at least once per day because they need to be dealt with separately
  less.than.once.per.day <- subset(fitted.chore.durations, completions_per_day < 1)
  at.least.once.per.day <- subset(fitted.chore.durations, completions_per_day >= 1)
  # Scale at most once per day to completions per day
  less.than.once.per.day$mean_log_duration_minutes <- scale.log.normal.mean(less.than.once.per.day$mean_log_duration_minutes, less.than.once.per.day$completions_per_day)
  less.than.once.per.day$mode_duration_minutes <- log.normal.mode(less.than.once.per.day$mean_log_duration_minutes, less.than.once.per.day$sd_log_duration_minutes)
  less.than.once.per.day$median_duration_minutes <- log.normal.median(less.than.once.per.day$mean_log_duration_minutes, less.than.once.per.day$sd_log_duration_minutes)
  less.than.once.per.day$mean_duration_minutes <- log.normal.mean(less.than.once.per.day$mean_log_duration_minutes, less.than.once.per.day$sd_log_duration_minutes)
  # Recombine with chores that have 1 or more completions per day
  rbind(less.than.once.per.day, at.least.once.per.day)
}

sum.chores <- function (fitted.chore.durations) {
  accumulator <- 0
  for(i in 1:nrow(fitted.chore.durations)) {
    chore.data <- fitted.chore.durations[i,]
    mean.log <- chore.data$mean_log_duration_minutes
    sd.log <- chore.data$sd_log_duration_minutes
    accumulator <- accumulator + rvlnorm(mean=mean.log, sd=sd.log)
  }
  return(accumulator)
}

sum.chores.histogram <- function (sims, title, left.tail = 0.0001, right.tail = 0.995) {
  quantiles <- quantile(sims, c(0.5, 0.95, left.tail, right.tail))
  xmin <- floor(quantiles[[3]])
  xmax <- ceiling(quantiles[[4]])
  cat(title, "
    Median:", quantiles[["50%"]], "
    Mean:", mean(sims), "
    95% CI UB:", quantiles[["95%"]], "\n")
  Filter(function (value) {
    value >= xmin & value <= xmax
  }, sims) %>%
    hist(breaks = 100, freq = FALSE, main = title, xlab = paste(title, "duration (minutes)"))
}

analyze.meals <- function (fitted.chore.durations, weekendity) {
  weekend.label <- ifelse(weekendity, "Weekend", "Weekday")
  all.meal.chores <- NULL
  for (meal in c("breakfast", "lunch", "dinner")) {
    meal.chores <- data.frame(chore=c(paste("make", meal), paste("eat", meal), paste(meal, "dishes"), "put away dishes"), aggregate_key=weekendity)
    if (is.null(all.meal.chores)) {
      all.meal.chores <- meal.chores
    } else {
      all.meal.chores <- rbind(all.meal.chores, meal.chores)
    }
    merge(fitted.chore.durations, meal.chores) %>% sum.chores %>% sum.chores.histogram(paste(weekend.label, meal))
  }
  merge(fitted.chore.durations, all.meal.chores) %>% sum.chores %>% sum.chores.histogram(paste(weekend.label, "meals"))
}

main <- function () {
  setnsims(1000000)
  using.database(function (fetch.query.results) {
    chore.durations.sql <- "SELECT *, weekendity(due_date) AS weekendity
      FROM hierarchical_chore_completion_durations
      JOIN chore_completions USING (chore_completion_id)
      JOIN chore_schedule USING (chore_completion_id)
      JOIN chores USING (chore_id)
      WHERE chore_completion_status_id = 4"
    fitted.chore.durations.sql <- "SELECT *, chore_id IN (SELECT chore_id FROM chore_hierarchy) AS child_chore
      FROM chore_durations_per_day
      LEFT JOIN chore_categories USING (chore_id)
      WHERE is_active"
    chore.durations <- fetch.query.results(chore.durations.sql)
    fitted.chore.durations <- fetch.query.results(fitted.chore.durations.sql)
    chore.histograms(chore.durations, fitted.chore.durations)
    # fitted.chore.durations %>%
    #  subset(daily == 1 & weekendity == 0 & child_chore == 0) %>%
    #  expand.many.chore.completions.per.day %>%
    #  scale.less.than.one.chore.completion.per.day %>%
    #  sum.chores %>%
    #  sum.chores.histogram("Weekday chores")
    # subset(fitted.chore.durations, daily == 1 & weekendity == 0 & child_chore == 0 & (is.na(category_id) | category_id != 1)) %>%
    #  chore.breakdown.chart("Weekday chore breakdown")
  })
}
