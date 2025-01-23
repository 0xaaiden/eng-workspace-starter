WITH day_nums AS (
    SELECT 
        ROW_NUMBER() OVER (ORDER BY NULL) - 1 AS i
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))
),
days AS (
    SELECT DATEADD(day, i, '2023-03-16'::DATE) AS day
    FROM day_nums
    WHERE DATEADD(day, i, '2023-03-16'::DATE) <= '2028-01-01'
),

airdrop AS (
    SELECT
      d.day,
      CASE 
        WHEN d.day = '2023-03-23' THEN 10000000000 * 0.1162
        ELSE 0
      END AS daily_amount
    FROM days d
),

foundation AS (
    SELECT
      d.day,
      CASE
        WHEN d.day < '2023-04-17' THEN 0
        WHEN d.day >= '2027-04-17' THEN 0
        ELSE 750000000 / NULLIF(
          DATEDIFF(day, '2023-04-17'::DATE, '2027-04-17'::DATE),
          0
        )
      END AS daily_amount
    FROM days d
),

advisors_team AS (
    SELECT
      d.day,
      CASE
        WHEN d.day = '2024-03-16' THEN 2694000000 * 0.25
        ELSE 0
      END AS daily_amount
    FROM days d

    UNION ALL

    SELECT
      d.day,
      CASE
        WHEN d.day IN (
          '2024-04-16','2024-05-16','2024-06-16','2024-07-16','2024-08-16','2024-09-16','2024-10-16','2024-11-16','2024-12-16',
          '2025-01-16','2025-02-16','2025-03-16','2025-04-16','2025-05-16','2025-06-16','2025-07-16','2025-08-16','2025-09-16','2025-10-16','2025-11-16','2025-12-16',
          '2026-01-16','2026-02-16','2026-03-16','2026-04-16','2026-05-16','2026-06-16','2026-07-16','2026-08-16','2026-09-16','2026-10-16','2026-11-16','2026-12-16',
          '2027-01-16','2027-02-16','2027-03-16'
        )
        THEN (2694000000 * 0.75) / 36
        ELSE 0
      END
    FROM days d
),

investors AS (
    SELECT
      d.day,
      CASE
        WHEN d.day = '2024-03-16' THEN 1753000000 * 0.25
        ELSE 0
      END AS daily_amount
    FROM days d

    UNION ALL

    SELECT
      d.day,
      CASE
        WHEN d.day IN (
          '2024-04-16','2024-05-16','2024-06-16','2024-07-16','2024-08-16','2024-09-16','2024-10-16','2024-11-16','2024-12-16',
          '2025-01-16','2025-02-16','2025-03-16','2025-04-16','2025-05-16','2025-06-16','2025-07-16','2025-08-16','2025-09-16','2025-10-16','2025-11-16','2025-12-16',
          '2026-01-16','2026-02-16','2026-03-16','2026-04-16','2026-05-16','2026-06-16','2026-07-16','2026-08-16','2026-09-16','2026-10-16','2026-11-16','2026-12-16',
          '2027-01-16','2027-02-16','2027-03-16'
        )
        THEN (1753000000 * 0.75) / 36
        ELSE 0
      END
    FROM days d
),

dao_treasury AS (
    SELECT d.day, 0 AS daily_amount
    FROM days d
),

all_unlocks AS (
    SELECT day, daily_amount FROM airdrop
    UNION ALL
    SELECT day, daily_amount FROM foundation
    UNION ALL
    SELECT day, daily_amount FROM advisors_team
    UNION ALL
    SELECT day, daily_amount FROM investors
    UNION ALL
    SELECT day, daily_amount FROM dao_treasury
),

combined AS (
    SELECT
      d.day,
      COALESCE(u.daily_amount, 0) AS daily_amount
    FROM days d
    LEFT JOIN all_unlocks u
           ON d.day = u.day
),

daily_totals AS (
    SELECT
      day,
      SUM(daily_amount) AS daily_emission
    FROM combined
    GROUP BY day
)

SELECT
  day,
  daily_emission,
  SUM(daily_emission) OVER (
    ORDER BY day 
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS cumulative_emission
FROM daily_totals
ORDER BY day;