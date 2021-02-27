USE chores;

CREATE OR REPLACE VIEW frequency_category_ranges
AS
WITH minimum_periods AS (SELECT upper_bounds.frequency_category_id
        , MAX(lower_bounds.maximum_period_days) AS minimum_period_days
    FROM frequency_categories AS lower_bounds
    JOIN frequency_categories AS upper_bounds
        ON lower_bounds.maximum_period_days < upper_bounds.maximum_period_days
    GROUP BY upper_bounds.frequency_category_id),
minimum_period_frequency_categories AS (SELECT maximum_period_days AS minimum_period_days
        , NOT maximum_period_inclusive AS minimum_period_inclusive
    FROM frequency_categories)
SELECT frequency_category_id
        , frequency_category
        , COALESCE(minimum_period_days, 0) AS minimum_period_days
        , COALESCE(minimum_period_inclusive, 1) AS minimum_period_inclusive
        , maximum_period_days
        , maximum_period_inclusive
    FROM frequency_categories
    LEFT JOIN minimum_periods USING (frequency_category_id)
    LEFT JOIN minimum_period_frequency_categories USING (minimum_period_days);
