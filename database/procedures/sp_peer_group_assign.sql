USE aml_analytics;

DROP PROCEDURE IF EXISTS sp_peer_group_assign;

DELIMITER $$

CREATE PROCEDURE sp_peer_group_assign (
    IN p_peer_group_id  INT UNSIGNED,
    IN p_customer_type  VARCHAR(50),   -- NULL = don't filter on this field
    IN p_region         VARCHAR(100),  -- NULL = don't filter on this field
    IN p_product        VARCHAR(100)   -- NULL = don't filter on this field
)
sp_body: BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF NOT EXISTS (SELECT 1 FROM peer_group WHERE peer_group_id = p_peer_group_id) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_peer_group_assign: p_peer_group_id does not exist in peer_group';
    END IF;

    IF p_customer_type IS NULL AND p_region IS NULL AND p_product IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'sp_peer_group_assign: at least one matching criterion must be provided';
    END IF;

    START TRANSACTION;

    INSERT INTO account_peer_group (account_id, peer_group_id, assigned_at)
    SELECT a.account_id, p_peer_group_id, NOW()
    FROM accounts a
    WHERE (p_customer_type IS NULL OR a.customer_type = p_customer_type)
      AND (p_region        IS NULL OR a.region        = p_region)
      AND (p_product        IS NULL OR a.product        = p_product)
      AND NOT EXISTS (
          SELECT 1 FROM account_peer_group apg
          WHERE apg.account_id = a.account_id
            AND apg.peer_group_id = p_peer_group_id
      );

    UPDATE peer_group
    SET member_count = (
            SELECT COUNT(*) FROM account_peer_group
            WHERE peer_group_id = p_peer_group_id
        ),
        last_updated = NOW()
    WHERE peer_group_id = p_peer_group_id;

    COMMIT;
END sp_body$$

DELIMITER ;


-- test 

CALL sp_peer_group_assign(1, 'retail', 'APAC', 'current_account');
CALL sp_peer_group_assign(2, 'corporate', 'EU', 'trade_finance');
SELECT * FROM account_peer_group;
SELECT peer_group_id, group_name, member_count FROM peer_group;