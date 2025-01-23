WITH day_nums AS (
    SELECT ROW_NUMBER() OVER(ORDER BY NULL) - 1 AS i
    FROM TABLE(GENERATOR(ROWCOUNT => 5000))
),
days AS (
    SELECT DATEADD(day, i, '2020-03-16'::DATE) AS day
    FROM day_nums
    WHERE DATEADD(day, i, '2020-03-16'::DATE) <= CURRENT_DATE()
),
issuance AS (
    /* Combine staking and voting rewards per day */
    SELECT day, SUM(issuance) AS daily_issuance
    FROM (
        /* Staking rewards */
        SELECT 
            DATE_TRUNC(day, s.BLOCK_TIMESTAMP) AS day,
            SUM(s.REWARD_AMOUNT_SOL) AS issuance
        FROM solana.gov.fact_rewards_staking s
        GROUP BY 1

        UNION ALL

        /* Voting rewards */
        SELECT
            DATE_TRUNC(day, v.BLOCK_TIMESTAMP) AS day,
            SUM(v.REWARD_AMOUNT_SOL) AS issuance
        FROM solana.gov.fact_rewards_voting v
        GROUP BY 1
    ) combined
    GROUP BY day
)
SELECT
    d.day,
    COALESCE(i.daily_issuance, 0) AS daily_issuance
FROM days d
LEFT JOIN issuance i ON d.day = i.day
ORDER BY d.day;