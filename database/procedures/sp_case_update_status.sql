USE aml_analytics;

DROP PROCEDURE IF EXISTS sp_case_create;

DELIMITER $$

CREATE PROCEDURE sp_case_create (
    IN p_transaction_id BIGINT UNSIGNED,
    IN p_analyst_id INT UNSIGNED,
    IN p_status VARCHAR(20),
    IN p_notes TEXT
)
sp_body: BEGIN
    DECLARE v_role VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    IF NOT EXISTS (SELECT 1 FROM transactions WHERE transaction_id = p_transaction_id) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sp_case_create: transaction_id does not exist';
    END IF;

    SELECT role INTO v_role FROM users WHERE user_id = p_analyst_id;
    IF v_role IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sp_case_create: analyst_id does not exist';
    END IF;
    IF v_role NOT IN ('analyst', 'manager') THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sp_case_create: only analyst or manager roles may create cases';
    END IF;

    IF EXISTS (
        SELECT 1 FROM case_notes
        WHERE transaction_id = p_transaction_id AND status <> 'cleared'
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'sp_case_create: an active case already exists for this transaction';
    END IF;

    START TRANSACTION;

    INSERT INTO case_notes (transaction_id, analyst_id, status, notes)
    VALUES (p_transaction_id, p_analyst_id, IFNULL(p_status, 'reviewed'), p_notes);

    COMMIT;

    SELECT LAST_INSERT_ID() AS case_id;
END sp_body$$

DELIMITER ;