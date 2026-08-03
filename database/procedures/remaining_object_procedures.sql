USE aml_analytics;

-- =====================================================================
-- sp_report_generate
-- Aggregates a period's metrics and logs an immutable report record.
-- The actual snapshot lives in the exported file at file_path; this
-- procedure's result set is what FastAPI writes to that file.
-- =====================================================================


DROP PROCEDURE IF EXISTS sp_report_generate;
DELIMITER $$
CREATE PROCEDURE sp_report_generate (
    IN p_report_type VARCHAR(10),
    IN p_period_start DATE,
    IN p_period_end DATE,
    IN p_generated_by INT UNSIGNED,
    IN p_file_path VARCHAR(500)
)
sp_body: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF p_report_type NOT IN ('daily','weekly','monthly') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sp_report_generate: invalid report_type';
    END IF;
    IF p_period_end < p_period_start THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sp_report_generate: period_end must not be before period_start';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM users WHERE user_id = p_generated_by) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sp_report_generate: generated_by user does not exist';
    END IF;

    START TRANSACTION;
    INSERT INTO reports (report_type, generated_by, period_start, period_end, file_path)
    VALUES (p_report_type, p_generated_by, p_period_start, p_period_end, p_file_path);
    COMMIT;

    SELECT
        LAST_INSERT_ID() AS report_id,
        COUNT(DISTINCT t.transaction_id) AS total_transactions,
        SUM(CASE WHEN r.risk_label = 'high' THEN 1 ELSE 0 END) AS high_risk_count,
        SUM(CASE WHEN c.status = 'escalated' THEN 1 ELSE 0 END) AS escalated_cases,
        SUM(CASE WHEN c.status = 'cleared' THEN 1 ELSE 0 END) AS cleared_cases,
        ROUND(AVG(t.amount), 2) AS avg_transaction_amount
    FROM transactions t
    LEFT JOIN risk_scores r ON r.transaction_id = t.transaction_id
    LEFT JOIN case_notes c ON c.transaction_id = t.transaction_id
    WHERE t.txn_timestamp BETWEEN p_period_start AND p_period_end;
END sp_body$$
DELIMITER ;

-- =====================================================================
-- vw_risk_scores_latest
-- Tiebreaker uses risk_score_id, not just created_at (two scores written
-- within the same second would otherwise both match MAX(created_at)).
-- =====================================================================
DROP VIEW IF EXISTS vw_risk_scores_latest;
CREATE VIEW vw_risk_scores_latest AS
SELECT rs.*
FROM risk_scores rs
JOIN (
    SELECT transaction_id, MAX(risk_score_id) AS latest_id
    FROM risk_scores
    GROUP BY transaction_id
) latest ON latest.transaction_id = rs.transaction_id AND latest.latest_id = rs.risk_score_id;

-- =====================================================================
-- vw_account_baseline_deviation
-- =====================================================================
DROP VIEW IF EXISTS vw_account_baseline_deviation;
CREATE VIEW vw_account_baseline_deviation AS
SELECT
    t.transaction_id, t.sender_account, t.receiver_account, t.amount, t.txn_timestamp,
    ab.account_id AS baseline_account_id, ab.avg_amount, ab.stddev_amount,
    CASE
        WHEN ab.stddev_amount IS NULL OR ab.stddev_amount = 0 THEN NULL
        ELSE ROUND((t.amount - ab.avg_amount) / ab.stddev_amount, 2)
    END AS z_score
FROM transactions t
JOIN account_baseline ab ON ab.account_id = t.sender_account;

-- =====================================================================
-- vw_peer_group_anomaly
-- =====================================================================
DROP VIEW IF EXISTS vw_peer_group_anomaly;
CREATE VIEW vw_peer_group_anomaly AS
SELECT
    a.account_id, pg.peer_group_id, pg.group_name, ab.avg_amount AS account_avg_amount,
    pg.typical_range_amount_min, pg.typical_range_amount_max,
    CASE
        WHEN ab.avg_amount IS NULL OR pg.typical_range_amount_min IS NULL THEN NULL
        WHEN ab.avg_amount < pg.typical_range_amount_min OR ab.avg_amount > pg.typical_range_amount_max THEN 1
        ELSE 0
    END AS is_anomalous
FROM accounts a
JOIN account_peer_group apg ON apg.account_id = a.account_id
JOIN peer_group pg ON pg.peer_group_id = apg.peer_group_id
LEFT JOIN account_baseline ab ON ab.account_id = a.account_id;

-- =====================================================================
-- vw_case_queue
-- =====================================================================
DROP VIEW IF EXISTS vw_case_queue;
CREATE VIEW vw_case_queue AS
SELECT c.case_id, c.transaction_id, c.analyst_id, c.status, c.notes, c.created_at, c.updated_at
FROM case_notes c
WHERE c.status <> 'cleared'
ORDER BY CASE c.status WHEN 'escalated' THEN 0 ELSE 1 END, c.created_at ASC;