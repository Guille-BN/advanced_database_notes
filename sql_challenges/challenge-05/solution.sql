--Crear table pet_care_log
CREATE TABLE pet_care_log (
    product_id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    log_text VARCHAR2(500),
    log_datetime TIMESTAMP DEFAULT SYSTIMESTAMP,
    update_date TIMESTAMP DEFAULT SYSTIMESTAMP,
    updated_by_user VARCHAR2(50)
);

-- Insertar valores
INSERT INTO pet_care_log (log_text,updated_by_user)
VALUES ('Texto 1','Guillermo');
INSERT INTO pet_care_log (log_text,updated_by_user)
VALUES ('Texto 2','Wynter');
INSERT INTO pet_care_log (log_text,updated_by_user)
VALUES ('Texto 3','Hector');
INSERT INTO pet_care_log (log_text,updated_by_user)
VALUES ('Texto 4','Luciano');
INSERT INTO pet_care_log (log_text,updated_by_user)
VALUES ('Texto 5','Anette');
COMMIT;

--First trigger
CREATE OR REPLACE TRIGGER trigger_1
BEFORE INSERT ON pet_care_log
FOR EACH ROW
BEGIN
    :NEW.update_date := SYSTIMESTAMP;
    :NEW.updated_by_user := USER;
END;

--Second trigger
CREATE OR REPLACE TRIGGER trigger_1
BEFORE UPDATE ON pet_care_log
FOR EACH ROW
BEGIN
    IF (:NEW.updated_by_user != USER) THEN
        RAISE_APPLICATION_ERROR(
            -20002,
            'Cannot update: User does not match the last updated_by_user'
        );
    END IF;
END;

/*
TEST
update pet_care_log
set UPDATED_BY_USER ='Guillermo'
where product_id=21;
*/

--Third trigger
CREATE OR REPLACE TRIGGER trigger_3
BEFORE DELETE ON pet_care_log
FOR EACH ROW
BEGIN
    IF (USER != 'JOEMANAGER') THEN
        RAISE_APPLICATION_ERROR(
            -20003,
            'Cannot delete: User does not match JOEMANAGER'
        );
    END IF;
END;

/*
delete from pet_care_log
where product_id=2;
*/