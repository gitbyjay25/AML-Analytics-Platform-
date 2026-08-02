USE aml_analytics;

-- risk_scores: combined risk indicator per transaction

CREATE TABLE risk_scores (
    risk_score_id           BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transaction_id           BIGINT UNSIGNED NOT NULL,
    rule_flag_score           DECIMAL(5,2)   NOT NULL DEFAULT 0,   -- 0-100
    baseline_deviation_score  DECIMAL(5,2)   NOT NULL DEFAULT 0,   -- 0-100
    peer_anomaly_score        DECIMAL(5,2)   NOT NULL DEFAULT 0,   -- 0-100
    combined_score            DECIMAL(5,2)   NOT NULL DEFAULT 0,   -- 0-100
    risk_label                 ENUM('low', 'medium', 'high') NOT NULL DEFAULT 'low',
    model_id                   INT UNSIGNED  NULL,
    created_at                 DATETIME      NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_risk_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    INDEX idx_risk_transaction (transaction_id),
    INDEX idx_risk_label (risk_label)
) ENGINE = InnoDB;