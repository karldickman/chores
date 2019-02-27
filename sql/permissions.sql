USE chores;
GRANT EXECUTE ON PROCEDURE chores_completed_and_remaining TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE chore_duration_today TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE get_chore_completion TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE postpone_chore TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE show_chore_history TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE show_meal_chores TO 'chores'@'localhost';