USE aml_analytics;

CREATE TABLE account_baseline (
    account_id              VARCHAR(50)     PRIMARY KEY,
    avg_amount               DECIMAL(18,2)   NULL,
    stddev_amount              DECIMAL(18,2)   NULL,
    avg_frequency_per_week       DECIMAL(10,2)  NULL,
    common_countries               VARCHAR(255)    NULL,
    common_payment_types             VARCHAR(255)    NULL,
    last_updated                       DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_baseline_account FOREIGN KEY (account_id) REFERENCES accounts(account_id)
) ENGINE = InnoDB;