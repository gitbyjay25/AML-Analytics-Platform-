USE aml_analytics;

DROP PROCEDURE IF EXISTS sp_risk_score_upsert;

DELIMITER $$

CREATE PROCEDURE sp_risk_score_upsert (
    IN p_transaction_id BIGINT UNSIGNED,
    IN p_rule_flag_score DECIMAL(5,2),
    IN p_baseline_deviation_score DECIMAL(5,2),
    IN p_peer_anomaly_score DECIMAL(5,2),
    IN p_model_id INT UNSIGNED
)
sp_body: BEGIN
    DECLARE v_combined DECIMAL(5,2);
    DECLARE v_label VARCHAR(10);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF NOT EXISTS (SELECT 1 FROM transactions WHERE transaction_id = p_transaction_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sp_risk_score_upsert: transaction_id does not exist';
    END IF;

    IF p_rule_flag_score NOT BETWEEN 0 AND 100
       OR p_baseline_deviation_score NOT BETWEEN 0 AND 100
       OR p_peer_anomaly_score NOT BETWEEN 0 AND 100 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sp_risk_score_upsert: component scores must be between 0 and 100';
    END IF;

    IF p_model_id IS NOT NULL
       AND NOT EXISTS (SELECT 1 FROM model_metadata WHERE model_id = p_model_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sp_risk_score_upsert: model_id does not exist';
    END IF;

    SET v_combined = ROUND((p_rule_flag_score + p_baseline_deviation_score + p_peer_anomaly_score) / 3, 2);

    SET v_label = CASE
        WHEN v_combined >= 70 THEN 'high'
        WHEN v_combined >= 40 THEN 'medium'
        ELSE 'low'
    END;

    START TRANSACTION;

    INSERT INTO risk_scores (
        transaction_id, rule_flag_score, baseline_deviation_score,
        peer_anomaly_score, combined_score, risk_label, model_id
    ) VALUES (
        p_transaction_id, p_rule_flag_score, p_baseline_deviation_score,
        p_peer_anomaly_score, v_combined, v_label, p_model_id
    );

    COMMIT;

    SELECT LAST_INSERT_ID() AS risk_score_id, v_combined AS combined_score, v_label AS risk_label;
END sp_body$$

DELIMITER ;