USE aml_analytics;

DROP PROCEDURE IF EXISTS sp_peer_group_refresh;

DELIMITER $$

CREATE PROCEDURE sp_peer_group_refresh (
    IN p_peer_group_id  INT UNSIGNED,  -- NULL = refresh all peer groups
    IN p_days_back      INT            -- NULL = defaults to 90 (must match baseline window)
)
sp_body: BEGIN
    DECLARE v_days_back INT;
    DECLARE v_orig_safe_updates INT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        IF v_orig_safe_updates IS NOT NULL THEN
            SET SESSION sql_safe_updates = v_orig_safe_updates;
        END IF;
        RESIGNAL;
    END;

    IF p_peer_group_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM peer_group WHERE peer_group_id = p_peer_group_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_peer_group_refresh: p_peer_group_id does not exist in peer_group';
    END IF;

    IF p_days_back IS NOT NULL AND p_days_back <= 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_peer_group_refresh: p_days_back must be a positive integer';
    END IF;

    SET v_days_back = IFNULL(p_days_back, 90);

    -- Multi-table UPDATE...JOIN is blocked by safe-update mode regardless of WHERE
    -- clause (a well-known MySQL limitation). Toggle it off for just this
    -- procedure's execution, and always restore it afterward.
    SET v_orig_safe_updates = @@SESSION.sql_safe_updates;
    SET SESSION sql_safe_updates = 0;

    START TRANSACTION;

    UPDATE peer_group pg
    JOIN (
        SELECT peer_group_id,
               MIN(avg_amount)    AS min_amount,
               MAX(avg_amount)    AS max_amount,
               MIN(freq_per_week) AS min_freq,
               MAX(freq_per_week) AS max_freq
        FROM (
            SELECT peer_group_id, account_id,
                   AVG(amount)                   AS avg_amount,
                   COUNT(*) / (v_days_back / 7.0) AS freq_per_week
            FROM (
                SELECT apg.peer_group_id, t.sender_account AS account_id, t.amount
                FROM transactions t
                JOIN account_peer_group apg ON apg.account_id = t.sender_account
                WHERE t.txn_timestamp >= DATE_SUB(NOW(), INTERVAL v_days_back DAY)
                  AND (p_peer_group_id IS NULL OR apg.peer_group_id = p_peer_group_id)
                UNION ALL
                SELECT apg.peer_group_id, t.receiver_account AS account_id, t.amount
                FROM transactions t
                JOIN account_peer_group apg ON apg.account_id = t.receiver_account
                WHERE t.txn_timestamp >= DATE_SUB(NOW(), INTERVAL v_days_back DAY)
                  AND (p_peer_group_id IS NULL OR apg.peer_group_id = p_peer_group_id)
            ) member_txns
            GROUP BY peer_group_id, account_id
        ) account_stats
        GROUP BY peer_group_id
    ) group_ranges ON group_ranges.peer_group_id = pg.peer_group_id
    SET pg.typical_range_amount_min = group_ranges.min_amount,
        pg.typical_range_amount_max = group_ranges.max_amount,
        pg.typical_range_freq_min   = group_ranges.min_freq,
        pg.typical_range_freq_max   = group_ranges.max_freq,
        pg.last_updated             = NOW()
    WHERE pg.peer_group_id = group_ranges.peer_group_id;

    COMMIT;

    SET SESSION sql_safe_updates = v_orig_safe_updates;
END sp_body$$

DELIMITER ;
-- test 

CALL sp_peer_group_refresh(NULL, NULL);
SELECT peer_group_id, group_name, typical_range_amount_min, typical_range_amount_max,
       typical_range_freq_min, typical_range_freq_max
FROM peer_group;