USE chores;

CREATE OR REPLACE VIEW days_per_weekend
AS
SELECT FALSE AS daily, 7 AS days_per_weekend
UNION
SELECT TRUE AS daily, 2 AS days_per_weekend;
