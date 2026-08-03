USE aml_analytics;

-- reports: generated report metadata and export history

CREATE TABLE reports (
    report_id       INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    report_type      ENUM('daily', 'weekly', 'monthly') NOT NULL,
    generated_by      INT UNSIGNED  NOT NULL,
    period_start       DATE         NOT NULL,
    period_end         DATE         NOT NULL,
    file_path           VARCHAR(500) NULL,
    created_at           DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_report_user FOREIGN KEY (generated_by) REFERENCES users(user_id)
) ENGINE = InnoDB;