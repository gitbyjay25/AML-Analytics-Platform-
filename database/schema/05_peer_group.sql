USE aml_analytics;

CREATE TABLE peer_group (
    peer_group_id             INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    group_name                 VARCHAR(150)   NOT NULL,
    segment_criteria             VARCHAR(255)   NOT NULL,
    typical_range_amount_min       DECIMAL(18,2)  NULL,
    typical_range_amount_max         DECIMAL(18,2)  NULL,
    typical_range_freq_min             DECIMAL(10,2)  NULL,
    typical_range_freq_max               DECIMAL(10,2)  NULL,
    member_count                           INT UNSIGNED   NOT NULL DEFAULT 0,
    last_updated                             DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;