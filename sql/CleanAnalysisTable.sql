CREATE OR REPLACE TABLE `rakaminkimiafarma.kimia_farma.kf_analysis_cleaned` AS
WITH cleaned_data AS (
    SELECT 
        -- Remove duplicates
        DISTINCT t.transaction_id,

        -- Standardize and clean columns
        t.date,
        t.branch_id,
        COALESCE(c.branch_name, 'Unknown') AS branch_name,  -- Handle missing branch names
        COALESCE(c.kota, 'Unknown') AS kota,
        COALESCE(c.provinsi, 'Unknown') AS provinsi,
        IFNULL(c.rating, 0) AS rating_cabang,  -- Replace NULL ratings with 0

        COALESCE(t.customer_name, 'Guest') AS customer_name,  -- Handle missing customer names
        t.product_id,
        COALESCE(p.product_name, 'Unknown') AS product_name,  -- Handle missing product names
        SAFE_CAST(p.price AS FLOAT64) AS actual_price,  -- Ensure price is numeric
        SAFE_CAST(t.discount_percentage AS FLOAT64) AS discount_percentage,  -- Ensure discount is numeric
        
        -- Ensure discount is within a reasonable range (0-100%)
        CASE 
            WHEN t.discount_percentage < 0 THEN 0
            WHEN t.discount_percentage > 100 THEN 100
            ELSE t.discount_percentage
        END AS cleaned_discount_percentage,

        -- Calculate net sales (price after discount) and ensure it's valid
        GREATEST(p.price * (1 - t.discount_percentage / 100), 0) AS nett_sales,

        -- Updated profit margin based on new price tiers
        CASE 
            WHEN p.price <= 50000 THEN 0.10
            WHEN p.price > 50000 AND p.price <= 100000 THEN 0.15
            WHEN p.price > 100000 AND p.price <= 500000 THEN 0.20
            WHEN p.price > 500000 AND p.price <= 800000 THEN 0.25
            ELSE 0.30  -- For products above 800,000
        END AS persentase_gross_laba,

        -- Ensure net profit is non-negative, using updated price tiers
        GREATEST(
            (p.price * (1 - t.discount_percentage / 100)) * 
            CASE 
                WHEN p.price <= 50000 THEN 0.10
                WHEN p.price > 50000 AND p.price <= 100000 THEN 0.15
                WHEN p.price > 100000 AND p.price <= 500000 THEN 0.20
                WHEN p.price > 500000 AND p.price <= 800000 THEN 0.25
                ELSE 0.30
            END, 0
        ) AS nett_profit,

        -- Ensure ratings are within a valid range (e.g., 0-5)
        CASE 
            WHEN t.rating_cabang < 0 THEN 0
            WHEN t.rating_cabang > 5 THEN 5
            ELSE t.rating_cabang
        END AS rating_transaksi

    FROM `rakaminkimiafarma.kimia_farma.kf_analysis` t
    JOIN `rakaminkimiafarma.kimia_farma.kf_product` p 
        ON t.product_id = p.product_id
    JOIN `rakaminkimiafarma.kimia_farma.kf_kantor_cabang` c 
        ON t.branch_id = c.branch_id
)
SELECT * FROM cleaned_data;