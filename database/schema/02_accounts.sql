USE aml_analytics;

CREATE TABLE accounts (
    account_id      VARCHAR(50)         PRIMARY KEY,
    customer_type   VARCHAR(50)         NULL,
    region          VARCHAR(100)        NULL,
    product         VARCHAR(100)        NULL,
    opened_at       DATE                NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_accounts_segment (customer_type, region, product)
) ENGINE = InnoDB;