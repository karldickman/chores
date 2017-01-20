ROLLBACK;
START TRANSACTION;
SET @is_completed = TRUE;
CALL complete_chore(<{chore_name}>, <{when_completed}>, <{chore_due_date}>, FALSE, <{minutes FLOAT}>, <{seconds FLOAT}>, @is_completed, @chore_completion_id, @chore_session_id);
CALL show_completed_chore(@chore_completion_id);
/* COMMIT */