USE aml_analytics;

-- case_notes: analyst annotations, status, audit trail

CREATE TABLE case_notes (
    case_id         BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    transaction_id   BIGINT UNSIGNED NOT NULL,
    analyst_id        INT UNSIGNED   NOT NULL,
    status             ENUM('reviewed', 'escalated', 'cleared') NOT NULL DEFAULT 'reviewed',
    notes               TEXT         NULL,
    created_at           DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at           DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_case_transaction FOREIGN KEY (transaction_id) REFERENCES transactions(transaction_id),
    CONSTRAINT fk_case_analyst     FOREIGN KEY (analyst_id)     REFERENCES users(user_id),
    INDEX idx_case_transaction (transaction_id),
    INDEX idx_case_status (status),
    INDEX idx_case_analyst (analyst_id)
) ENGINE = InnoDB;