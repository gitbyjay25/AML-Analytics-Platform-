USE aml_analytics;

CREATE TABLE transactions (
    transaction_id    BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    sender_account     VARCHAR(50)        NOT NULL,
    receiver_account   VARCHAR(50)        NOT NULL,
    amount              DECIMAL(18,2)      NOT NULL,
    currency             CHAR(3)            NOT NULL,
    country               VARCHAR(100)       NOT NULL,
    payment_type           VARCHAR(50)        NOT NULL,
    txn_timestamp             DATETIME           NOT NULL,
    label                       ENUM('fraud', 'normal') NULL,
    created_at                    DATETIME           NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_txn_sender   FOREIGN KEY (sender_account)   REFERENCES accounts(account_id),
    CONSTRAINT fk_txn_receiver FOREIGN KEY (receiver_account) REFERENCES accounts(account_id),
    INDEX idx_txn_sender_time   (sender_account, txn_timestamp),
    INDEX idx_txn_receiver_time (receiver_account, txn_timestamp),
    INDEX idx_txn_timestamp     (txn_timestamp),
    INDEX idx_txn_country       (country),
    INDEX idx_txn_payment_type  (payment_type)
) ENGINE = InnoDB;