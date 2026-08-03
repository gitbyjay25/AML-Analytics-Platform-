USE aml_analytics;

-- model_metadata: versioning and metadata for the risk scoring model

CREATE TABLE model_metadata (
    model_id        INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    model_name       VARCHAR(150)   NOT NULL,
    version           VARCHAR(30)   NOT NULL,
    trained_at         DATETIME     NULL,
    description         TEXT        NULL,
    metrics_json         JSON       NULL,   -- precision/recall/etc.
    is_active             TINYINT(1) NOT NULL DEFAULT 0,
    created_at             DATETIME  NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_model_name_version (model_name, version)
) ENGINE = InnoDB;

