USE aml_analytics;

DROP PROCEDURE IF EXISTS sp_case_update_status;

DELIMITER $$

CREATE PROCEDURE sp_case_update_status (
    IN p_case_id INT UNSIGNED,
    IN p_new_status VARCHAR(20),
    IN p_notes TEXT
)
sp_body: BEGIN
    DECLARE v_current_status VARCHAR(20);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT status
    INTO v_current_status
    FROM case_notes
    WHERE case_id = p_case_id;

    IF v_current_status IS NULL THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'sp_case_update_status: case_id does not exist';
    END IF;

    IF p_new_status NOT IN ('reviewed', 'escalated', 'cleared') THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'sp_case_update_status: invalid status value';
    END IF;

    IF v_current_status = 'cleared' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'sp_case_update_status: case is cleared (terminal state) - open a new case instead';
    END IF;

    START TRANSACTION;

    UPDATE case_notes
    SET
        status = p_new_status,
        notes = IFNULL(p_notes, notes),
        updated_at = NOW()
    WHERE case_id = p_case_id;

    COMMIT;

END sp_body$$

DELIMITER ;