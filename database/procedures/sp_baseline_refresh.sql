USE aml_analytics;

DROP PROCEDURE IF EXISTS sp_baseline_refresh;

DELIMITER $$

CREATE PROCEDURE sp_baseline_refresh (
    IN p_account_id  VARCHAR(50),   -- NULL = refresh all accounts
    IN p_days_back   INT            -- NULL = defaults to 90
)
sp_body: BEGIN
    DECLARE v_days_back INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_account_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM accounts WHERE account_id = p_account_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_baseline_refresh: p_account_id does not exist in accounts';
    END IF;

    IF p_days_back IS NOT NULL AND p_days_back <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_baseline_refresh: p_days_back must be a positive integer';
    END IF;

    SET v_days_back = IFNULL(p_days_back, 90);

    START TRANSACTION;

    INSERT INTO account_baseline (
        account_id, avg_amount, stddev_amount, avg_frequency_per_week,
        common_countries, common_payment_types, last_updated
    )
    WITH account_txns AS (
        SELECT sender_account AS account_id, amount, country, payment_type
        FROM transactions
        WHERE txn_timestamp >= DATE_SUB(NOW(), INTERVAL v_days_back DAY)
          AND (p_account_id IS NULL OR sender_account = p_account_id)
        UNION ALL
        SELECT receiver_account AS account_id, amount, country, payment_type
        FROM transactions
        WHERE txn_timestamp >= DATE_SUB(NOW(), INTERVAL v_days_back DAY)
          AND (p_account_id IS NULL OR receiver_account = p_account_id)
    ),
    stats AS (
        SELECT account_id,
               AVG(amount)         AS avg_amount,
               STDDEV_SAMP(amount) AS stddev_amount,
               COUNT(*)            AS txn_count
        FROM account_txns
        GROUP BY account_id
    ),
    country_counts AS (
        SELECT account_id, country, COUNT(*) AS cnt
        FROM account_txns
        GROUP BY account_id, country
    ),
    top_countries AS (
        SELECT account_id,
               SUBSTRING_INDEX(GROUP_CONCAT(country ORDER BY cnt DESC SEPARATOR ','), ',', 3) AS common_countries
        FROM country_counts
        GROUP BY account_id
    ),
    payment_counts AS (
        SELECT account_id, payment_type, COUNT(*) AS cnt
        FROM account_txns
        GROUP BY account_id, payment_type
    ),
    top_payments AS (
        SELECT account_id,
               SUBSTRING_INDEX(GROUP_CONCAT(payment_type ORDER BY cnt DESC SEPARATOR ','), ',', 3) AS common_payment_types
        FROM payment_counts
        GROUP BY account_id
    )
    SELECT
        s.account_id,
        s.avg_amount,
        s.stddev_amount,
        s.txn_count / (v_days_back / 7.0) AS avg_frequency_per_week,
        tc.common_countries,
        tp.common_payment_types,
        NOW()
    FROM stats s
    LEFT JOIN top_countries tc ON tc.account_id = s.account_id
    LEFT JOIN top_payments  tp ON tp.account_id = s.account_id
    ON DUPLICATE KEY UPDATE
        avg_amount              = VALUES(avg_amount),
        stddev_amount           = VALUES(stddev_amount),
        avg_frequency_per_week  = VALUES(avg_frequency_per_week),
        common_countries        = VALUES(common_countries),
        common_payment_types    = VALUES(common_payment_types),
        last_updated            = VALUES(last_updated);

    COMMIT;
END sp_body$$

DELIMITER ;

-- TEST 
CALL sp_baseline_refresh(NULL, NULL);
SELECT * FROM account_baseline;