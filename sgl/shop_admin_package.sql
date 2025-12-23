-- 1. Создаем спецификацию пакета
CREATE OR REPLACE PACKAGE HEAD_ADMIN.SHOP_ADMIN_PACKAGE AS
    
    -- Процедура получения записи типа TABLE_FLOWER_SHOP с заданным ID
    PROCEDURE GET_FLOWER_SHOP_BY_ID(
        P_SHOP_ID IN INT,
        P_RESULT OUT TABLE_SHOP
    );
    
    -- Процедура получения записи типа TABLE_FLOWER_SHOP по идентификатору администратора
    PROCEDURE GET_FLOWER_SHOP_BY_ADMIN(
        P_ADMIN_ID IN INT,
        P_RESULT OUT TABLE_SHOP
    );
    
    -- Процедура получения записей типа TABLE_COURIER для заданного магазина
    PROCEDURE GET_COURIER_BY_SHOP(
        P_SHOP_ID IN INT,
        P_RESULT OUT TABLE_COURIER
    );
    
    -- Процедура получения записей типа TABLE_COURIER с заданным идентификатором
    PROCEDURE GET_COURIER_BY_ID(
        P_COURIER_ID IN INT,
        P_RESULT OUT TABLE_COURIER
    );
    
    -- Процедура добавления нового курьера
    PROCEDURE INSERT_COURIER(
        FULL_NAME HEAD_ADMIN.PERSONAL_DATA.FULL_NAME%TYPE,
        EMAIL HEAD_ADMIN.PERSONAL_DATA.EMAIL%TYPE,
        PHONE_NUMBER HEAD_ADMIN.PERSONAL_DATA.PHONE_NUMBER%TYPE,
        DATE_OF_BIRTH IN VARCHAR2,
        SALARY HEAD_ADMIN.COURIER.SALARY%TYPE,
        VEHICLE_TYPE HEAD_ADMIN.COURIER.VEHICLE_TYPE%TYPE,
        SHOP_ID INT
    );
    
    -- Процедура обновления данных курьера
    PROCEDURE UPDATE_COURIER(
        P_ID INT,
        P_SALARY HEAD_ADMIN.COURIER.SALARY%TYPE DEFAULT NULL,
        P_VEHICLE_TYPE VARCHAR2 DEFAULT NULL,
        P_IS_ACTIVE NUMBER DEFAULT NULL,
        P_IS_AVAILABLE NUMBER DEFAULT NULL
    );
    
    -- Процедура удаления курьера
    PROCEDURE DELETE_COURIER(
        P_ID INT
    );
    
END SHOP_ADMIN_PACKAGE;
/


-- 2. Создаем тело пакета
CREATE OR REPLACE PACKAGE BODY HEAD_ADMIN.SHOP_ADMIN_PACKAGE AS

    PROCEDURE GET_FLOWER_SHOP_BY_ID(
        P_SHOP_ID IN INT,
        P_RESULT OUT TABLE_SHOP
    ) IS
    BEGIN
        SELECT RECORD_SHOP(
                       FS.ID,
                       FS.SHOP_NAME,
                       FS.ADDRESS,
                       SDO_UTIL.TO_GEOJSON(FS.LOCATION),
                       SDO_UTIL.TO_GEOJSON(FS.COVERAGE_AREA),
                       FS.SHOP_ADMIN_ID,
                       TO_CHAR(FS.OPEN_TIME, 'HH24:MI'),
                       TO_CHAR(FS.CLOSE_TIME, 'HH24:MI'),
                       TO_CHAR(FS.DELIVERY_START_TIME, 'HH24:MI'),
                       TO_CHAR(FS.DELIVERY_END_TIME, 'HH24:MI'),
                       FS.IS_ACTIVE
                   ) BULK COLLECT
        INTO P_RESULT
        FROM HEAD_ADMIN.FLOWER_SHOP FS
        WHERE FS.ID = P_SHOP_ID;

        IF P_RESULT.COUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Внимание: Магазин с ID=' || P_SHOP_ID || ' не найден.');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка получения данных магазина: ' || SQLERRM);
            P_RESULT := TABLE_SHOP();
    END GET_FLOWER_SHOP_BY_ID;

    PROCEDURE GET_FLOWER_SHOP_BY_ADMIN(
        P_ADMIN_ID IN INT,
        P_RESULT OUT TABLE_SHOP
    ) IS
    BEGIN
        SELECT RECORD_SHOP(
                       FS.ID,
                       FS.SHOP_NAME,
                       FS.ADDRESS,
                       SDO_UTIL.TO_GEOJSON(FS.LOCATION),
                       SDO_UTIL.TO_GEOJSON(FS.COVERAGE_AREA),
                       FS.SHOP_ADMIN_ID,
                       TO_CHAR(FS.OPEN_TIME, 'HH24:MI'),
                       TO_CHAR(FS.CLOSE_TIME, 'HH24:MI'),
                       TO_CHAR(FS.DELIVERY_START_TIME, 'HH24:MI'),
                       TO_CHAR(FS.DELIVERY_END_TIME, 'HH24:MI'),
                       FS.IS_ACTIVE
                   ) BULK COLLECT
        INTO P_RESULT
        FROM HEAD_ADMIN.FLOWER_SHOP FS
        WHERE FS.SHOP_ADMIN_ID = P_ADMIN_ID;

        IF P_RESULT.COUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Внимание: Магазин для администратора с ID=' || P_ADMIN_ID || ' не найден.');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка получения данных магазина: ' || SQLERRM);
            P_RESULT := TABLE_SHOP();
    END GET_FLOWER_SHOP_BY_ADMIN;

    PROCEDURE GET_COURIER_BY_SHOP(
        P_SHOP_ID IN INT,
        P_RESULT OUT TABLE_COURIER
    ) IS
    BEGIN
        SELECT RECORD_COURIER(
                       C.ID,
                       PD.FULL_NAME,
                       PD.EMAIL,
                       PD.PHONE_NUMBER,
                       TO_CHAR(PD.DATE_OF_BIRTH, 'DD-MM-YYYY'),
                       C.SALARY,
                       C.VEHICLE_TYPE,
                       C.IS_ACTIVE,
                       C.IS_AVAILABLE
                   ) BULK COLLECT
        INTO P_RESULT
        FROM HEAD_ADMIN.COURIER C
                 JOIN HEAD_ADMIN.PERSONAL_DATA PD ON PD.ID = C.PERSONAL_DATA_ID
        WHERE C.FLOWER_SHOP_ID = P_SHOP_ID
        ORDER BY PD.FULL_NAME;

        IF P_RESULT.COUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Внимание: В магазине с ID=' || P_SHOP_ID || ' нет курьеров.');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка получения данных курьеров: ' || SQLERRM);
            P_RESULT := TABLE_COURIER();
    END GET_COURIER_BY_SHOP;

    PROCEDURE GET_COURIER_BY_ID(
        P_COURIER_ID IN INT,
        P_RESULT OUT TABLE_COURIER
    ) IS
    BEGIN
        SELECT RECORD_COURIER(
                       C.ID,
                       PD.FULL_NAME,
                       PD.EMAIL,
                       PD.PHONE_NUMBER,
                       TO_CHAR(PD.DATE_OF_BIRTH, 'DD-MM-YYYY'),
                       C.SALARY,
                       C.VEHICLE_TYPE,
                       C.IS_ACTIVE,
                       C.IS_AVAILABLE
                   ) BULK COLLECT
        INTO P_RESULT
        FROM HEAD_ADMIN.COURIER C
                 JOIN HEAD_ADMIN.PERSONAL_DATA PD ON PD.ID = C.PERSONAL_DATA_ID
        WHERE C.ID = P_COURIER_ID;

        IF P_RESULT.COUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Внимание: Курьер с ID=' || P_COURIER_ID || ' не найден.');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка получения данных курьера: ' || SQLERRM);
            P_RESULT := TABLE_COURIER();
    END GET_COURIER_BY_ID;

    PROCEDURE INSERT_COURIER(
        FULL_NAME HEAD_ADMIN.PERSONAL_DATA.FULL_NAME%TYPE,
        EMAIL HEAD_ADMIN.PERSONAL_DATA.EMAIL%TYPE,
        PHONE_NUMBER HEAD_ADMIN.PERSONAL_DATA.PHONE_NUMBER%TYPE,
        DATE_OF_BIRTH IN VARCHAR2,
        SALARY HEAD_ADMIN.COURIER.SALARY%TYPE,
        VEHICLE_TYPE HEAD_ADMIN.COURIER.VEHICLE_TYPE%TYPE,
        SHOP_ID INT
    ) IS
        V_DATA_ID HEAD_ADMIN.PERSONAL_DATA.ID%TYPE;
        V_SHOP_EXISTS NUMBER;
        V_DATE DATE;
    BEGIN
        SELECT COUNT(*) INTO V_SHOP_EXISTS 
        FROM HEAD_ADMIN.FLOWER_SHOP 
        WHERE ID = SHOP_ID AND IS_ACTIVE = 1;
        
        IF V_SHOP_EXISTS = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Магазин с ID=' || SHOP_ID || ' не существует или не активен.');
            RETURN;
        END IF;
        
        IF DATE_OF_BIRTH IS NOT NULL THEN
            BEGIN
                V_DATE := TO_DATE(DATE_OF_BIRTH, 'DD-MM-YYYY');
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Внимание: Некорректный формат даты рождения. Дата не установлена.');
                    V_DATE := NULL;
            END;
        ELSE
            V_DATE := NULL;
        END IF;
        
        BEGIN
            INSERT INTO HEAD_ADMIN.PERSONAL_DATA (FULL_NAME, EMAIL, PHONE_NUMBER, DATE_OF_BIRTH)
            VALUES (FULL_NAME, EMAIL, PHONE_NUMBER, V_DATE)
            RETURNING ID INTO V_DATA_ID;
            
            DBMS_OUTPUT.PUT_LINE('Персональные данные созданы с ID: ' || V_DATA_ID);
            
        EXCEPTION
            WHEN DUP_VAL_ON_INDEX THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка: Email или телефон уже существуют в системе.');
                ROLLBACK;
                RETURN;
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка при вставке персональных данных: ' || SQLERRM);
                ROLLBACK;
                RETURN;
        END;
        
        BEGIN
            INSERT INTO HEAD_ADMIN.COURIER (
                PERSONAL_DATA_ID, 
                SALARY, 
                VEHICLE_TYPE,
                FLOWER_SHOP_ID, 
                IS_ACTIVE, 
                IS_AVAILABLE,
                LAST_ACTIVE
            ) VALUES (
                V_DATA_ID, 
                SALARY, 
                VEHICLE_TYPE,
                SHOP_ID, 
                1, -- IS_ACTIVE = 1
                1, -- IS_AVAILABLE = 1
                SYSTIMESTAMP
            );
            
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Успех: Курьер добавлен. ID персональных данных: ' || V_DATA_ID);
            
        EXCEPTION
            WHEN OTHERS THEN
                ROLLBACK;
                DBMS_OUTPUT.PUT_LINE('Ошибка при добавлении курьера: ' || SQLERRM);
        END;
        
    END INSERT_COURIER;

    PROCEDURE UPDATE_COURIER(
        P_ID INT,
        P_SALARY HEAD_ADMIN.COURIER.SALARY%TYPE DEFAULT NULL,
        P_VEHICLE_TYPE VARCHAR2 DEFAULT NULL,
        P_IS_ACTIVE NUMBER DEFAULT NULL,
        P_IS_AVAILABLE NUMBER DEFAULT NULL
    ) IS
        V_IS_AVAILABLE NUMBER := P_IS_AVAILABLE;
        V_ROWS_UPDATED NUMBER;
    BEGIN
        IF P_IS_ACTIVE = 0 THEN
            V_IS_AVAILABLE := 0;
        END IF;

        UPDATE HEAD_ADMIN.COURIER
        SET SALARY = COALESCE(P_SALARY, SALARY),
            VEHICLE_TYPE = COALESCE(P_VEHICLE_TYPE, VEHICLE_TYPE),
            IS_ACTIVE = COALESCE(P_IS_ACTIVE, IS_ACTIVE),
            IS_AVAILABLE = COALESCE(V_IS_AVAILABLE, IS_AVAILABLE),
            LAST_ACTIVE = SYSTIMESTAMP
        WHERE ID = P_ID
        RETURNING 1 INTO V_ROWS_UPDATED;
        
        IF V_ROWS_UPDATED = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Внимание: Курьер с ID=' || P_ID || ' не найден.');
        ELSE
            COMMIT;
            DBMS_OUTPUT.PUT_LINE('Успех: Данные курьера ID=' || P_ID || ' обновлены');
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка обновления курьера: ' || SQLERRM);
    END UPDATE_COURIER;

    PROCEDURE DELETE_COURIER(
        P_ID INT
    ) IS
        V_COUNT         INT;
        V_PERSONAL_DATA INT;
        ACTIVE_ORDERS INT;
    BEGIN
        SELECT COUNT(*) INTO V_COUNT FROM HEAD_ADMIN.COURIER WHERE ID = P_ID;

        IF V_COUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Курьер с ID=' || P_ID || ' не существует.');
            RETURN;
        END IF;
        
        -- Проверяем, есть ли активные заказы у курьера
        SELECT COUNT(*) INTO ACTIVE_ORDERS
        FROM HEAD_ADMIN.USER_ORDER
        WHERE COURIER_ID = P_ID 
          AND STATUS IN ('ASSIGNED', 'DELIVERING');
          
        IF ACTIVE_ORDERS > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Невозможно удалить курьера с активными заказами.');
            RETURN;
        END IF;
        
        SELECT PERSONAL_DATA_ID INTO V_PERSONAL_DATA 
        FROM HEAD_ADMIN.COURIER WHERE ID = P_ID;
        
        DELETE FROM HEAD_ADMIN.COURIER WHERE ID = P_ID;
        
        DELETE FROM HEAD_ADMIN.PERSONAL_DATA WHERE ID = V_PERSONAL_DATA;

        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Успех: Курьер ID=' || P_ID || ' удален');
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Курьер с ID=' || P_ID || ' не найден.');
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка удаления курьера: ' || SQLERRM);
    END DELETE_COURIER;

END SHOP_ADMIN_PACKAGE;
/

-- 3. Проверка создания пакета
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== ПРОВЕРКА СОЗДАНИЯ ПАКЕТА SHOP_ADMIN_PACKAGE ===');
    DBMS_OUTPUT.PUT_LINE('=== ПАКЕТ УСПЕШНО СОЗДАН ===');
END;
/
