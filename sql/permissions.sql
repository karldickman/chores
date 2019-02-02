USE chores;
GRANT EXECUTE ON PROCEDURE chores.chores_completed_and_remaining TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE chores.chore_duration_today TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE chores.get_chore_completion TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE chores.postpone_chore TO 'chores'@'localhost';
GRANT EXECUTE ON PROCEDURE chores.show_meal_chores TO 'chores'@'localhost';