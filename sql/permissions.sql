USE chores;
GRANT SELECT ON aggregate_by TO 'chores'@'localhost';
GRANT SELECT ON aggregate_keys TO 'chores'@'localhost';
GRANT SELECT ON chores TO 'chores'@'localhost';
GRANT SELECT ON chore_categories TO 'chores'@'localhost';
GRANT SELECT ON chore_completion_next_due_dates TO 'chores'@'localhost';
GRANT SELECT ON chore_completion_overdue_statuses TO 'chores'@'localhost';
GRANT SELECT ON chore_completions TO 'chores'@'localhost';
GRANT SELECT ON chore_completions_when_completed TO 'chores'@'localhost';
GRANT SELECT ON chore_completion_statuses TO 'chores'@'localhost';
GRANT SELECT ON chore_duration_confidence_intervals TO 'chores'@'localhost';
GRANT SELECT ON chore_durations TO 'chores'@'localhost';
GRANT SELECT ON chore_durations_per_day TO 'chores'@'localhost';
GRANT SELECT ON chore_hierarchy TO 'chores'@'localhost';
GRANT SELECT ON chore_order TO 'chores'@'localhost';
GRANT SELECT ON chore_periods_days TO 'chores'@'localhost';
GRANT SELECT ON chore_schedule TO 'chores'@'localhost';
GRANT SELECT ON completions_needed TO 'chores'@'localhost';
GRANT SELECT ON frequency_category_ranges TO 'chores'@'localhost';
GRANT SELECT ON hierarchical_chore_completion_durations TO 'chores'@'localhost';
GRANT SELECT ON skippable_chores TO 'chores'@'localhost';
GRANT SELECT ON time_remaining_by_chore TO 'chores'@'localhost';
GRANT SELECT ON weekday_weekend_overlaps TO 'chores'@'localhost';
GRANT SELECT ON weekendities TO 'chores'@'localhost';
GRANT EXECUTE ON FUNCTION chore_completion_next_due_date TO 'chores'@'localhost';
GRANT EXECUTE ON FUNCTION weekendity TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE change_due_date TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE create_chore TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE create_chore_completion TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE chore_burndown TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE chores_completed_and_remaining TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE chore_duration_today TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE complete_chore TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE complete_chore_session TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE complete_chore_without_data TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE complete_unscheduled_chore TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE delete_chore_completion TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE hierarchize_chore_completion TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE get_chore_completion TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE postpone_chore_by_name TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE record_chore_completed TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE record_chore_session TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE schedule_chore TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE show_chore_completion TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE show_chore_completions_needed TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE show_chore_history TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE show_meal_chores TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE skip_chore TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE skippable_chores_pretty TO 'chores'@'localhost';
