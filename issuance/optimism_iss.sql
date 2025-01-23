WITH /* 1) Generate Calendar */
day_nums AS (
    SELECT ROW_NUMBER() OVER(ORDER BY NULL) - 1 AS i
    FROM TABLE(GENERATOR(ROWCOUNT => 2000))   -- Enough for ~5 years
),
days AS (
    SELECT DATEADD(day, i, '2022-06-01'::DATE) AS day
    FROM day_nums
    WHERE DATEADD(day, i, '2022-06-01'::DATE) <= '2027-01-01'   -- or CURRENT_DATE()
),

/* 2) Ecosystem Fund
   from snippet:
   manualLinear("2022-06-01", "2023-04-31", 94175479),
   manualLinear("2023-05-01", "2024-04-31", 90e6),
   manualLinear("2024-05-01", "2025-04-31", 94e6),
   manualLinear("2025-05-01", "2026-04-31", 108e6)
   Replacing "04-31" with "04-30" for each year.
*/
ecosystem_fund AS (
    SELECT
      d.day,
      CASE
        -- Interval #1: 2022-06-01 to 2023-04-30 => total = 94,175,479
        WHEN d.day < '2022-06-01' THEN 0
        WHEN d.day > '2023-04-30' THEN 0
        ELSE 94175479 / NULLIF(
          DATEDIFF(day, '2022-06-01'::DATE, '2023-05-01'::DATE),
          0
        )
      END AS daily_amount
    FROM days d

    UNION ALL

    SELECT
      d.day,
      CASE
        -- Interval #2: 2023-05-01 to 2024-04-30 => total = 90,000,000
        WHEN d.day < '2023-05-01' THEN 0
        WHEN d.day > '2024-04-30' THEN 0
        ELSE 90000000 / NULLIF(
          DATEDIFF(day, '2023-05-01'::DATE, '2024-05-01'::DATE),
          0
        )
      END
    FROM days d

    UNION ALL

    SELECT
      d.day,
      CASE
        -- Interval #3: 2024-05-01 to 2025-04-30 => total = 94,000,000
        WHEN d.day < '2024-05-01' THEN 0
        WHEN d.day > '2025-04-30' THEN 0
        ELSE 94000000 / NULLIF(
          DATEDIFF(day, '2024-05-01'::DATE, '2025-05-01'::DATE),
          0
        )
      END
    FROM days d

    UNION ALL

    SELECT
      d.day,
      CASE
        -- Interval #4: 2025-05-01 to 2026-04-30 => total = 108,000,000
        WHEN d.day < '2025-05-01' THEN 0
        WHEN d.day > '2026-04-30' THEN 0
        ELSE 108000000 / NULLIF(
          DATEDIFF(day, '2025-05-01'::DATE, '2026-05-01'::DATE),
          0
        )
      END
    FROM days d
),

/* 3) Retroactive Public Goods Funding
   from snippet:
   manualLinear("2022-06-01", "2023-04-31", 3710574),
   manualLinear("2023-05-01", "2024-04-31", 9e7),
   manualLinear("2024-05-01", "2025-04-31", 12e7),
   manualLinear("2025-05-01", "2026-04-31", 42e7)
   Replace "04-31" with "04-30".
*/
retroactive_pgf AS (
    SELECT
      d.day,
      CASE
        -- Interval #1: 2022-06-01 to 2023-04-30 => total = 3,710,574
        WHEN d.day < '2022-06-01' THEN 0
        WHEN d.day > '2023-04-30' THEN 0
        ELSE 3710574 / NULLIF(
          DATEDIFF(day, '2022-06-01', '2023-05-01'),
          0
        )
      END AS daily_amount
    FROM days d

    UNION ALL

    SELECT
      d.day,
      CASE
        -- Interval #2: 2023-05-01 to 2024-04-30 => total = 90,000,000
        WHEN d.day < '2023-05-01' THEN 0
        WHEN d.day > '2024-04-30' THEN 0
        ELSE 90000000 / NULLIF(
          DATEDIFF(day, '2023-05-01', '2024-05-01'),
          0
        )
      END
    FROM days d

    UNION ALL

    SELECT
      d.day,
      CASE
        -- Interval #3: 2024-05-01 to 2025-04-30 => total = 120,000,000
        WHEN d.day < '2024-05-01' THEN 0
        WHEN d.day > '2025-04-30' THEN 0
        ELSE 120000000 / NULLIF(
          DATEDIFF(day, '2024-05-01', '2025-05-01'),
          0
        )
      END
    FROM days d

    UNION ALL

    SELECT
      d.day,
      CASE
        -- Interval #4: 2025-05-01 to 2026-04-30 => total = 420,000,000
        WHEN d.day < '2025-05-01' THEN 0
        WHEN d.day > '2026-04-30' THEN 0
        ELSE 420000000 / NULLIF(
          DATEDIFF(day, '2025-05-01', '2026-05-01'),
          0
        )
      END
    FROM days d
),

/* 4) Airdrops (manualCliff)
   from snippet:
   Airdrops: [
     manualCliff("2022-06-01", qty * 0.05),
     manualCliff("2023-02-09", 11742277),
   ],
   qty=4294967296 => 0.05 * qty=214748364.8
*/
airdrops AS (
    /* Cliff #1: 2022-06-01 -> 0.05*4294967296 = 214748364.8 (approx) */
    SELECT
      d.day,
      CASE
        WHEN d.day = '2022-06-01' THEN (4294967296 * 0.05)
        ELSE 0
      END AS daily_amount
    FROM days d

    UNION ALL

    /* Cliff #2: 2023-02-09 -> 11742277 */
    SELECT
      d.day,
      CASE
        WHEN d.day = '2023-02-09' THEN 11742277
        ELSE 0
      END
    FROM days d
),

/* 5) Team
   from snippet:
   Team: [
     manualCliff("2023-05-31", qty * 0.19 * 0.25),
     manualStep("2023-05-31", periodToSeconds.month, 36, (qty * 0.19 * 0.75) / 36),
   ]
   => cliff on 2023-05-31 for (4294967296 * 0.19 * 0.25)
      monthly steps (36) from 2023-05-31 for the rest 75% of 0.19.
*/
team AS (
    /* Cliff lumpsum on 2023-05-31 */
    SELECT
      d.day,
      CASE
        WHEN d.day = '2023-05-31' THEN (4294967296 * 0.19 * 0.25)
        ELSE 0
      END AS daily_amount
    FROM days d

    UNION ALL

    /* 36 monthly lumps from 2023-06-30, 2023-07-31, etc. up to 2026-05-31. 
       each lumpsum = (qty*0.19*0.75)/36
    */
    SELECT
      d.day,
      CASE
        WHEN d.day IN (
          '2023-06-30','2023-07-31','2023-08-31','2023-09-30','2023-10-31','2023-11-30','2023-12-31',
          '2024-01-31','2024-02-29','2024-03-31','2024-04-30','2024-05-31','2024-06-30','2024-07-31',
          '2024-08-31','2024-09-30','2024-10-31','2024-11-30','2024-12-31',
          '2025-01-31','2025-02-28','2025-03-31','2025-04-30','2025-05-31','2025-06-30','2025-07-31',
          '2025-08-31','2025-09-30','2025-10-31','2025-11-30','2025-12-31',
          '2026-01-31','2026-02-28','2026-03-31','2026-04-30','2026-05-31'
        )
        THEN (4294967296 * 0.19 * 0.75) / 36
        ELSE 0
      END
    FROM days d
),

/* 6) Investors
   from snippet:
   Investors: [
     manualCliff("2023-05-31", qty * 0.17 * 0.25),
     manualStep("2023-05-31", periodToSeconds.month, 36, (qty * 0.17 * 0.75) / 36),
   ]
*/
investors AS (
    /* Cliff lumpsum on 2023-05-31 => (4294967296 * 0.17 * 0.25) */
    SELECT
      d.day,
      CASE
        WHEN d.day = '2023-05-31' THEN (4294967296 * 0.17 * 0.25)
        ELSE 0
      END AS daily_amount
    FROM days d

    UNION ALL

    /* 36 monthly lumps from 2023-06-30 to 2026-05-31 
       => (qty*0.17*0.75)/36 each
    */
    SELECT
      d.day,
      CASE
        WHEN d.day IN (
          '2023-06-30','2023-07-31','2023-08-31','2023-09-30','2023-10-31','2023-11-30','2023-12-31',
          '2024-01-31','2024-02-29','2024-03-31','2024-04-30','2024-05-31','2024-06-30','2024-07-31',
          '2024-08-31','2024-09-30','2024-10-31','2024-11-30','2024-12-31',
          '2025-01-31','2025-02-28','2025-03-31','2025-04-30','2025-05-31','2025-06-30','2025-07-31',
          '2025-08-31','2025-09-30','2025-10-31','2025-11-30','2025-12-31',
          '2026-01-31','2026-02-28','2026-03-31','2026-04-30','2026-05-31'
        )
        THEN (4294967296 * 0.17 * 0.75) / 36
        ELSE 0
      END
    FROM days d
),
/* 1) UNION all categories together into one table. */
all_unlocks AS (
    SELECT day, daily_amount FROM ecosystem_fund
    UNION ALL
    SELECT day, daily_amount FROM retroactive_pgf
    UNION ALL
    SELECT day, daily_amount FROM airdrops
    UNION ALL
    SELECT day, daily_amount FROM team
    UNION ALL
    SELECT day, daily_amount FROM investors
),

/* 2) Join onto `days` so we see every date. */
combined AS (
    SELECT
      d.day,
      COALESCE(a.daily_amount, 0) AS daily_amount
    FROM days d
    LEFT JOIN all_unlocks a
           ON d.day = a.day
),
daily_totals AS (
    SELECT
      day,
      SUM(daily_amount) AS daily_emission
    FROM combined
    GROUP BY day
)

/* 2) Compute cumulative by using a window function on daily_emission */
SELECT
  day,
  daily_emission,
  /* Running total from the earliest day up through the current row’s day */
  SUM(daily_emission) 
    OVER (ORDER BY day 
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
    AS cumulative_emission
FROM daily_totals
ORDER BY day;