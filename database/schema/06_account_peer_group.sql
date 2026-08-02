USE aml_analytics;

-- Junction table: an account can belong to more than one peer group

CREATE TABLE account_peer_group (
    account_id      VARCHAR(50)     NOT NULL,
    peer_group_id   INT UNSIGNED    NOT NULL,
    assigned_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (account_id, peer_group_id),
    CONSTRAINT fk_apg_account   FOREIGN KEY (account_id)    REFERENCES accounts(account_id),
    CONSTRAINT fk_apg_peergroup FOREIGN KEY (peer_group_id) REFERENCES peer_group(peer_group_id)
) ENGINE = InnoDB;