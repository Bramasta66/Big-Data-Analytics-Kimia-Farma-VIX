WITH price_stats AS (
    SELECT 
        price,
        COUNT(*) AS frequency
    FROM `rakaminkimiafarma.kimia_farma.kf_product`
    GROUP BY price
),
ranked_prices AS (
    SELECT 
        price,
        frequency,
        SUM(frequency) OVER (ORDER BY price) AS cumulative_count,
        SUM(frequency) OVER () AS total_count
    FROM price_stats
)

SELECT 
    MIN(price) AS min_price,
    MAX(price) AS max_price,
    ROUND(AVG(price), 2) AS avg_price,
    -- Calculate Mode (Most Frequent Price)
    ARRAY_AGG(price ORDER BY frequency DESC LIMIT 1)[OFFSET(0)] AS mode_price,
    COUNT(*) AS total_products
FROM ranked_prices;