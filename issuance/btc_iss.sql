
WITH day_nums AS (
    /* Generate a date range from Bitcoin’s genesis date to current day */
    SELECT ROW_NUMBER() OVER (ORDER BY NULL) - 1 AS i
    FROM TABLE(GENERATOR(ROWCOUNT => 6000))  -- ~16+ years since 2009
),
days AS (
    SELECT DATEADD(day, i, '2009-01-03'::DATE) AS day
    FROM day_nums
    WHERE DATEADD(day, i, '2009-01-03'::DATE) <= CURRENT_DATE()
),
daily_issuance AS (
    /* Sum block rewards for each day */
    SELECT
        DATE_TRUNC(day, block_timestamp) AS day,
        SUM(BLOCK_REWARD) / 1 AS daily_issuance_btc
    FROM bitcoin.GOV.EZ_MINER_REWARDS
    GROUP BY 1
)
SELECT
    d.day,
    COALESCE(i.daily_issuance_btc, 0) AS daily_issuance_btc
FROM days d
LEFT JOIN daily_issuance i
       ON d.day = i.day
ORDER BY d.day;