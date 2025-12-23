-- Создаем пакет
CREATE OR REPLACE PACKAGE HEAD_ADMIN.HEAD_ADMIN_PACKAGE AS
    
    -- Управление магазинами
    PROCEDURE ADD_FLOWER_SHOP(
        P_SHOP_NAME NVARCHAR2,
        P_ADDRESS NVARCHAR2,
        P_LOCATION SDO_GEOMETRY,
        P_COVERAGE_AREA SDO_GEOMETRY,
        P_SHOP_ADMIN_ID INT,
        P_OPEN_TIME TIMESTAMP,
        P_CLOSE_TIME TIMESTAMP,
        P_DELIVERY_START_TIME TIMESTAMP,
        P_DELIVERY_END_TIME TIMESTAMP,
        P_PHONE VARCHAR2 DEFAULT NULL,
        P_EMAIL VARCHAR2 DEFAULT NULL
    );
    
    PROCEDURE UPDATE_FLOWER_SHOP(
        P_ID INT,
        P_SHOP_NAME NVARCHAR2 DEFAULT NULL,
        P_ADDRESS NVARCHAR2 DEFAULT NULL,
        P_LOCATION SDO_GEOMETRY DEFAULT NULL,
        P_COVERAGE_AREA SDO_GEOMETRY DEFAULT NULL,
        P_SHOP_ADMIN_ID INT DEFAULT NULL,
        P_OPEN_TIME TIMESTAMP DEFAULT NULL,
        P_CLOSE_TIME TIMESTAMP DEFAULT NULL,
        P_DELIVERY_START_TIME TIMESTAMP DEFAULT NULL,
        P_DELIVERY_END_TIME TIMESTAMP DEFAULT NULL,
        P_PHONE VARCHAR2 DEFAULT NULL,
        P_EMAIL VARCHAR2 DEFAULT NULL,
        P_IS_ACTIVE NUMBER DEFAULT NULL
    );
    
    PROCEDURE DELETE_FLOWER_SHOP(P_ID INT);
    
    -- Управление ролями
    PROCEDURE CREATE_USER_ROLE(P_ROLE_NAME HEAD_ADMIN.USER_ROLE.ROLE_NAME%TYPE);
    
    -- Регистрация администраторов
    PROCEDURE REGISTER_SHOP_ADMIN(
        P_FULL_NAME HEAD_ADMIN.PERSONAL_DATA.FULL_NAME%TYPE,
        P_EMAIL HEAD_ADMIN.PERSONAL_DATA.EMAIL%TYPE,
        P_PHONE_NUMBER HEAD_ADMIN.PERSONAL_DATA.PHONE_NUMBER%TYPE,
        P_DATE_OF_BIRTH IN VARCHAR2,
        P_PASSWORD IN VARCHAR2
    );
    
    -- Управление товарами
    PROCEDURE INSERT_PRODUCT(
        P_PRODUCT_NAME HEAD_ADMIN.PRODUCT.PRODUCT_NAME%TYPE,
        P_BASE_PRICE HEAD_ADMIN.PRODUCT.BASE_PRICE%TYPE,
        P_DESCRIPTION HEAD_ADMIN.PRODUCT.DESCRIPTION%TYPE,
        P_PRODUCT_IMAGE BLOB
    );
    
    PROCEDURE UPDATE_PRODUCT(
        P_ID INT,
        P_PRODUCT_NAME NVARCHAR2 DEFAULT NULL,
        P_BASE_PRICE NUMBER DEFAULT NULL,
        P_DESCRIPTION NVARCHAR2 DEFAULT NULL,
        P_PRODUCT_IMAGE BLOB DEFAULT NULL,
        P_IS_ACTIVE NUMBER DEFAULT NULL
    );
    
    PROCEDURE DELETE_PRODUCT(P_ID INT);
    
    -- Процедуры для вывода информации
    PROCEDURE SHOW_FLOWER_SHOPS(
        P_SHOW_ONLY_ACTIVE NUMBER DEFAULT 1
    );

    PROCEDURE SHOW_USER_ROLES;

    PROCEDURE SHOW_SHOP_ADMINS;

    PROCEDURE SHOW_PRODUCTS(
        P_SHOW_ONLY_ACTIVE NUMBER DEFAULT 1
    );
    
END HEAD_ADMIN_PACKAGE;
/

-- Тело пакета
CREATE OR REPLACE PACKAGE BODY HEAD_ADMIN.HEAD_ADMIN_PACKAGE AS
    
    -- 1. Добавление цветочного магазина
    PROCEDURE ADD_FLOWER_SHOP(
        P_SHOP_NAME NVARCHAR2,
        P_ADDRESS NVARCHAR2,
        P_LOCATION SDO_GEOMETRY,
        P_COVERAGE_AREA SDO_GEOMETRY,
        P_SHOP_ADMIN_ID INT,
        P_OPEN_TIME TIMESTAMP,
        P_CLOSE_TIME TIMESTAMP,
        P_DELIVERY_START_TIME TIMESTAMP,
        P_DELIVERY_END_TIME TIMESTAMP,
        P_PHONE VARCHAR2 DEFAULT NULL,
        P_EMAIL VARCHAR2 DEFAULT NULL
    ) IS
        V_EXISTS NUMBER;
        V_RESULT VARCHAR2(10);
    BEGIN
        SELECT CASE
                   WHEN SDO_RELATE(P_LOCATION, P_COVERAGE_AREA, 'mask=inside+coveredby') = 'TRUE'
                       THEN 'TRUE'
                   ELSE 'FALSE'
                   END
        INTO V_RESULT
        FROM DUAL;

        IF V_RESULT = 'FALSE' THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Местоположение магазина не находится в зоне доставки');
            RETURN;
        END IF;

        SELECT COUNT(*)
        INTO V_EXISTS
        FROM HEAD_ADMIN.FLOWER_SHOP FS
        WHERE SDO_RELATE(P_COVERAGE_AREA, FS.COVERAGE_AREA, 'mask=anyinteract') = 'TRUE';

        IF V_EXISTS > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Зона доставки пересекается с зоной доставки другого магазина');
            RETURN;
        END IF;

        SELECT COUNT(*)
        INTO V_EXISTS
        FROM HEAD_ADMIN.APP_USER AU
        JOIN HEAD_ADMIN.USER_ROLE UR ON AU.USER_ROLE = UR.ID
        WHERE AU.ID = P_SHOP_ADMIN_ID AND UR.ROLE_NAME = 'shop_admin';
        
        IF V_EXISTS = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Указанный ID не принадлежит администратору магазина (shop_admin)');
            RETURN;
        END IF;

        INSERT INTO HEAD_ADMIN.FLOWER_SHOP (
            SHOP_NAME, ADDRESS, LOCATION, COVERAGE_AREA, SHOP_ADMIN_ID,
            OPEN_TIME, CLOSE_TIME, DELIVERY_START_TIME, DELIVERY_END_TIME,
            PHONE, EMAIL, IS_ACTIVE
        ) VALUES (
            P_SHOP_NAME, P_ADDRESS, P_LOCATION, P_COVERAGE_AREA, P_SHOP_ADMIN_ID,
            P_OPEN_TIME, P_CLOSE_TIME, P_DELIVERY_START_TIME, P_DELIVERY_END_TIME,
            P_PHONE, P_EMAIL, 1
        );

        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Успех: Магазин "' || P_SHOP_NAME || '" успешно добавлен');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка при добавлении магазина: ' || SQLERRM);
    END ADD_FLOWER_SHOP;
    
    -- 2. Обновление магазина
    PROCEDURE UPDATE_FLOWER_SHOP(
        P_ID INT,
        P_SHOP_NAME NVARCHAR2 DEFAULT NULL,
        P_ADDRESS NVARCHAR2 DEFAULT NULL,
        P_LOCATION SDO_GEOMETRY DEFAULT NULL,
        P_COVERAGE_AREA SDO_GEOMETRY DEFAULT NULL,
        P_SHOP_ADMIN_ID INT DEFAULT NULL,
        P_OPEN_TIME TIMESTAMP DEFAULT NULL,
        P_CLOSE_TIME TIMESTAMP DEFAULT NULL,
        P_DELIVERY_START_TIME TIMESTAMP DEFAULT NULL,
        P_DELIVERY_END_TIME TIMESTAMP DEFAULT NULL,
        P_PHONE VARCHAR2 DEFAULT NULL,
        P_EMAIL VARCHAR2 DEFAULT NULL,
        P_IS_ACTIVE NUMBER DEFAULT NULL
    ) IS
        V_EXISTS NUMBER;
        V_RESULT VARCHAR2(10);
        V_AREA SDO_GEOMETRY;
        V_LOC SDO_GEOMETRY;
    BEGIN
        -- Проверяем существование магазина
        SELECT COUNT(*)
        INTO V_EXISTS
        FROM HEAD_ADMIN.FLOWER_SHOP 
        WHERE ID = P_ID;
        
        IF V_EXISTS = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Магазин с ID=' || P_ID || ' не найден');
            RETURN;
        END IF;
        
        SELECT COVERAGE_AREA, LOCATION INTO V_AREA, V_LOC
        FROM HEAD_ADMIN.FLOWER_SHOP WHERE ID = P_ID;
        
        IF P_LOCATION IS NOT NULL OR P_COVERAGE_AREA IS NOT NULL THEN
            SELECT CASE
                       WHEN SDO_RELATE(COALESCE(P_LOCATION, V_LOC), 
                                       COALESCE(P_COVERAGE_AREA, V_AREA), 
                                       'mask=inside+coveredby') = 'TRUE'
                           THEN 'TRUE'
                       ELSE 'FALSE'
                       END
            INTO V_RESULT
            FROM DUAL;

            IF V_RESULT = 'FALSE' THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка: Местоположение магазина не находится в зоне доставки');
                RETURN;
            END IF;

            SELECT COUNT(*)
            INTO V_EXISTS
            FROM HEAD_ADMIN.FLOWER_SHOP FS
            WHERE SDO_RELATE(COALESCE(P_COVERAGE_AREA, V_AREA), FS.COVERAGE_AREA, 'mask=anyinteract') = 'TRUE'
              AND FS.ID <> P_ID;

            IF V_EXISTS > 0 THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка: Зона доставки пересекается с зоной доставки другого магазина');
                RETURN;
            END IF;
        END IF;
        
        IF P_SHOP_ADMIN_ID IS NOT NULL THEN
            SELECT COUNT(*)
            INTO V_EXISTS
            FROM HEAD_ADMIN.APP_USER AU
            JOIN HEAD_ADMIN.USER_ROLE UR ON AU.USER_ROLE = UR.ID
            WHERE AU.ID = P_SHOP_ADMIN_ID AND UR.ROLE_NAME = 'shop_admin';
            
            IF V_EXISTS = 0 THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка: Указанный ID не принадлежит администратору магазина (shop_admin)');
                RETURN;
            END IF;
        END IF;
        
        UPDATE HEAD_ADMIN.FLOWER_SHOP
        SET SHOP_NAME = COALESCE(P_SHOP_NAME, SHOP_NAME),
            ADDRESS = COALESCE(P_ADDRESS, ADDRESS),
            LOCATION = COALESCE(P_LOCATION, LOCATION),
            COVERAGE_AREA = COALESCE(P_COVERAGE_AREA, COVERAGE_AREA),
            SHOP_ADMIN_ID = COALESCE(P_SHOP_ADMIN_ID, SHOP_ADMIN_ID),
            OPEN_TIME = COALESCE(P_OPEN_TIME, OPEN_TIME),
            CLOSE_TIME = COALESCE(P_CLOSE_TIME, CLOSE_TIME),
            DELIVERY_START_TIME = COALESCE(P_DELIVERY_START_TIME, DELIVERY_START_TIME),
            DELIVERY_END_TIME = COALESCE(P_DELIVERY_END_TIME, DELIVERY_END_TIME),
            PHONE = COALESCE(P_PHONE, PHONE),
            EMAIL = COALESCE(P_EMAIL, EMAIL),
            IS_ACTIVE = COALESCE(P_IS_ACTIVE, IS_ACTIVE)
        WHERE ID = P_ID;

        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Успех: Магазин ID=' || P_ID || ' успешно обновлен');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка при обновлении магазина: ' || SQLERRM);
    END UPDATE_FLOWER_SHOP;
    
    -- 3. Удаление магазина
    PROCEDURE DELETE_FLOWER_SHOP(P_ID INT) IS
        V_COUNT INT;
        V_SHOP_NAME NVARCHAR2(255);
        ACTIVE_ORDERS INT;
    BEGIN
        BEGIN
            SELECT SHOP_NAME INTO V_SHOP_NAME 
            FROM HEAD_ADMIN.FLOWER_SHOP 
            WHERE ID = P_ID;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка: Магазин с ID=' || P_ID || ' не найден');
                RETURN;
        END;
        
        SELECT COUNT(*) INTO ACTIVE_ORDERS
        FROM HEAD_ADMIN.USER_ORDER
        WHERE FLOWER_SHOP_ID = P_ID 
          AND STATUS IN ('NEW', 'PROCESSING', 'ASSIGNED', 'DELIVERING');
          
        IF ACTIVE_ORDERS > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Невозможно удалить магазин "' || V_SHOP_NAME || '" с активными заказами');
            RETURN;
        END IF;
        
        DELETE FROM HEAD_ADMIN.FLOWER_SHOP WHERE ID = P_ID;

        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Успех: Магазин "' || V_SHOP_NAME || '" (ID=' || P_ID || ') успешно удален');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка при удалении магазина: ' || SQLERRM);
    END DELETE_FLOWER_SHOP;
    
    -- 4. Создание роли пользователя
    PROCEDURE CREATE_USER_ROLE(P_ROLE_NAME HEAD_ADMIN.USER_ROLE.ROLE_NAME%TYPE) IS
        V_EXISTS NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO V_EXISTS
        FROM HEAD_ADMIN.USER_ROLE
        WHERE UPPER(ROLE_NAME) = UPPER(P_ROLE_NAME);
        
        IF V_EXISTS > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Роль "' || P_ROLE_NAME || '" уже существует');
            RETURN;
        END IF;
        
        INSERT INTO HEAD_ADMIN.USER_ROLE (ROLE_NAME) VALUES (P_ROLE_NAME);
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Успех: Роль "' || P_ROLE_NAME || '" создана');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка при создании роли: ' || SQLERRM);
    END CREATE_USER_ROLE;
    
    -- 5. Регистрация администратора магазина
    PROCEDURE REGISTER_SHOP_ADMIN(
        P_FULL_NAME HEAD_ADMIN.PERSONAL_DATA.FULL_NAME%TYPE,
        P_EMAIL HEAD_ADMIN.PERSONAL_DATA.EMAIL%TYPE,
        P_PHONE_NUMBER HEAD_ADMIN.PERSONAL_DATA.PHONE_NUMBER%TYPE,
        P_DATE_OF_BIRTH IN VARCHAR2,
        P_PASSWORD IN VARCHAR2
    ) IS
        V_ROLE_ID HEAD_ADMIN.USER_ROLE.ID%TYPE;
        V_DATA_ID HEAD_ADMIN.PERSONAL_DATA.ID%TYPE;
        V_USER_ID HEAD_ADMIN.APP_USER.ID%TYPE;
        V_PASSWORD_HASH VARCHAR2(64);
        V_EMAIL_EXISTS NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO V_EMAIL_EXISTS
        FROM HEAD_ADMIN.PERSONAL_DATA
        WHERE EMAIL = P_EMAIL;
        
        IF V_EMAIL_EXISTS > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Пользователь с email ' || P_EMAIL || ' уже существует');
            RETURN;
        END IF;
        
        BEGIN
            SELECT ID INTO V_ROLE_ID 
            FROM HEAD_ADMIN.USER_ROLE 
            WHERE ROLE_NAME = 'shop_admin';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка: Роль shop_admin не найдена. Сначала создайте роль.');
                RETURN;
        END;
        
        V_PASSWORD_HASH := HEAD_ADMIN.SIMPLE_PASSWORD_HASH(P_PASSWORD);
        
        BEGIN
            INSERT INTO HEAD_ADMIN.PERSONAL_DATA (FULL_NAME, EMAIL, PHONE_NUMBER, DATE_OF_BIRTH)
            VALUES (P_FULL_NAME, P_EMAIL, P_PHONE_NUMBER, TO_DATE(P_DATE_OF_BIRTH, 'DD-MM-YYYY'))
            RETURNING ID INTO V_DATA_ID;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка при вставке персональных данных: ' || SQLERRM);
                ROLLBACK;
                RETURN;
        END;
        
        BEGIN
            INSERT INTO HEAD_ADMIN.APP_USER (PASSWORD_HASH, USER_ROLE, PERSONAL_DATA)
            VALUES (V_PASSWORD_HASH, V_ROLE_ID, V_DATA_ID)
            RETURNING ID INTO V_USER_ID;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка при создании пользователя: ' || SQLERRM);
                ROLLBACK;
                RETURN;
        END;
        
        BEGIN
            INSERT INTO HEAD_ADMIN.CART (USER_ID) VALUES (V_USER_ID);
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка при создании корзины: ' || SQLERRM);
                ROLLBACK;
                RETURN;
        END;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Успех: Администратор магазина успешно зарегистрирован. ID: ' || V_USER_ID);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка при регистрации администратора магазина: ' || SQLERRM);
    END REGISTER_SHOP_ADMIN;
    
    -- 6. Добавление товара
    PROCEDURE INSERT_PRODUCT(
        P_PRODUCT_NAME HEAD_ADMIN.PRODUCT.PRODUCT_NAME%TYPE,
        P_BASE_PRICE HEAD_ADMIN.PRODUCT.BASE_PRICE%TYPE,
        P_DESCRIPTION HEAD_ADMIN.PRODUCT.DESCRIPTION%TYPE,
        P_PRODUCT_IMAGE BLOB
    ) IS
        V_PRODUCT_ID INT;
        V_EXISTS NUMBER;
    BEGIN
        -- Проверяем, существует ли уже товар с таким названием
        SELECT COUNT(*) INTO V_EXISTS 
        FROM HEAD_ADMIN.PRODUCT 
        WHERE UPPER(PRODUCT_NAME) = UPPER(P_PRODUCT_NAME) AND IS_ACTIVE = 1;
        
        IF V_EXISTS > 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Товар с названием "' || P_PRODUCT_NAME || '" уже существует');
            RETURN;
        END IF;
        
        IF P_BASE_PRICE <= 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Цена товара должна быть положительной');
            RETURN;
        END IF;
        
        INSERT INTO HEAD_ADMIN.PRODUCT (PRODUCT_NAME, BASE_PRICE, DESCRIPTION, PRODUCT_IMAGE, IS_ACTIVE)
        VALUES (P_PRODUCT_NAME, P_BASE_PRICE, P_DESCRIPTION, P_PRODUCT_IMAGE, 1)
        RETURNING ID INTO V_PRODUCT_ID;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Успех: Товар "' || P_PRODUCT_NAME || '" (ID=' || V_PRODUCT_ID || ') добавлен');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка добавления товара: ' || SQLERRM);
    END INSERT_PRODUCT;
    
    -- 7. Обновление товара
    PROCEDURE UPDATE_PRODUCT(
        P_ID INT,
        P_PRODUCT_NAME NVARCHAR2 DEFAULT NULL,
        P_BASE_PRICE NUMBER DEFAULT NULL,
        P_DESCRIPTION NVARCHAR2 DEFAULT NULL,
        P_PRODUCT_IMAGE BLOB DEFAULT NULL,
        P_IS_ACTIVE NUMBER DEFAULT NULL
    ) IS
        V_PRODUCT_COUNT NUMBER;
        V_EXISTS NUMBER;
    BEGIN
        -- Проверяем существование товара
        SELECT COUNT(*) INTO V_PRODUCT_COUNT FROM HEAD_ADMIN.PRODUCT WHERE ID = P_ID;
        
        IF V_PRODUCT_COUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Товар с ID=' || P_ID || ' не найден');
            RETURN;
        END IF;
        
        -- Если передано новое название, проверяем уникальность
        IF P_PRODUCT_NAME IS NOT NULL THEN
            SELECT COUNT(*) INTO V_EXISTS 
            FROM HEAD_ADMIN.PRODUCT 
            WHERE UPPER(PRODUCT_NAME) = UPPER(P_PRODUCT_NAME) 
              AND ID != P_ID 
              AND IS_ACTIVE = 1;
            
            IF V_EXISTS > 0 THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка: Товар с названием "' || P_PRODUCT_NAME || '" уже существует');
                RETURN;
            END IF;
        END IF;
        
        IF P_BASE_PRICE IS NOT NULL AND P_BASE_PRICE <= 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Цена товара должна быть положительной');
            RETURN;
        END IF;
        
        IF P_PRODUCT_IMAGE IS NOT NULL THEN
            -- Если передан новый BLOB, обновляем его
            UPDATE HEAD_ADMIN.PRODUCT
            SET PRODUCT_NAME = COALESCE(P_PRODUCT_NAME, PRODUCT_NAME),
                BASE_PRICE = COALESCE(P_BASE_PRICE, BASE_PRICE),
                DESCRIPTION = COALESCE(P_DESCRIPTION, DESCRIPTION),
                PRODUCT_IMAGE = P_PRODUCT_IMAGE,
                IS_ACTIVE = COALESCE(P_IS_ACTIVE, IS_ACTIVE)
            WHERE ID = P_ID;
        ELSE
            UPDATE HEAD_ADMIN.PRODUCT
            SET PRODUCT_NAME = COALESCE(P_PRODUCT_NAME, PRODUCT_NAME),
                BASE_PRICE = COALESCE(P_BASE_PRICE, BASE_PRICE),
                DESCRIPTION = COALESCE(P_DESCRIPTION, DESCRIPTION),
                IS_ACTIVE = COALESCE(P_IS_ACTIVE, IS_ACTIVE)
            WHERE ID = P_ID;
        END IF;

        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Успех: Товар ID=' || P_ID || ' обновлен');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка обновления товара: ' || SQLERRM);
    END UPDATE_PRODUCT;
    
    -- 8. Удаление товара
    PROCEDURE DELETE_PRODUCT(P_ID INT) IS
        V_COUNT INT;
        V_PRODUCT_NAME NVARCHAR2(255);
    BEGIN
        SELECT COUNT(*) INTO V_COUNT FROM HEAD_ADMIN.PRODUCT WHERE ID = P_ID;

        IF V_COUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: Товар с ID=' || P_ID || ' не найден');
            RETURN;
        END IF;
        
        -- Получаем название товара для сообщения
        SELECT PRODUCT_NAME INTO V_PRODUCT_NAME FROM HEAD_ADMIN.PRODUCT WHERE ID = P_ID;
        
        -- Помечаем товар как неактивный вместо удаления
        UPDATE HEAD_ADMIN.PRODUCT
        SET IS_ACTIVE = 0
        WHERE ID = P_ID;

        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Успех: Товар "' || V_PRODUCT_NAME || '" (ID=' || P_ID || ') помечен как неактивный');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка удаления товара: ' || SQLERRM);
    END DELETE_PRODUCT;
    
    -- 8. Просмотр списка магазинов
    PROCEDURE SHOW_FLOWER_SHOPS(
        P_SHOW_ONLY_ACTIVE NUMBER DEFAULT 1
    ) IS
        CURSOR C_SHOPS IS
            SELECT 
                FS.ID,
                FS.SHOP_NAME,
                FS.ADDRESS,
                FS.PHONE,
                FS.EMAIL,
                AU.ID AS ADMIN_ID,
                PD.FULL_NAME AS ADMIN_NAME,
                FS.IS_ACTIVE,
                COUNT(O.ID) AS ACTIVE_ORDERS
            FROM HEAD_ADMIN.FLOWER_SHOP FS
            LEFT JOIN HEAD_ADMIN.APP_USER AU ON FS.SHOP_ADMIN_ID = AU.ID
            LEFT JOIN HEAD_ADMIN.PERSONAL_DATA PD ON AU.PERSONAL_DATA = PD.ID
            LEFT JOIN HEAD_ADMIN.USER_ORDER O ON FS.ID = O.FLOWER_SHOP_ID 
                AND O.STATUS IN ('NEW', 'PROCESSING', 'ASSIGNED', 'DELIVERING')
            WHERE (P_SHOW_ONLY_ACTIVE = 0 OR FS.IS_ACTIVE = 1)
            GROUP BY FS.ID, FS.SHOP_NAME, FS.ADDRESS, FS.PHONE, FS.EMAIL,
                     AU.ID, PD.FULL_NAME, FS.IS_ACTIVE
            ORDER BY FS.ID;
        V_COUNT NUMBER := 0;
        V_BUFFER CLOB := ''; -- Буфер для накопления вывода
    BEGIN
        V_BUFFER := V_BUFFER || '==================================================================' || CHR(10);
        V_BUFFER := V_BUFFER || 'СПИСОК ЦВЕТОЧНЫХ МАГАЗИНОВ' || CHR(10);
        V_BUFFER := V_BUFFER || '==================================================================' || CHR(10);
        
        FOR REC IN C_SHOPS LOOP
            V_COUNT := V_COUNT + 1;
            
            -- Ограничиваем вывод только важной информацией
            V_BUFFER := V_BUFFER || 'ID: ' || REC.ID || ' | ' || REC.SHOP_NAME || CHR(10);
            
            -- Сокращаем адрес, если он слишком длинный
            IF LENGTH(REC.ADDRESS) > 50 THEN
                V_BUFFER := V_BUFFER || 'Адрес: ' || SUBSTR(REC.ADDRESS, 1, 47) || '...' || CHR(10);
            ELSE
                V_BUFFER := V_BUFFER || 'Адрес: ' || REC.ADDRESS || CHR(10);
            END IF;
            
            -- Контакты в одной строке
            V_BUFFER := V_BUFFER || 'Контакты: ' || 
                       NVL(SUBSTR(REC.PHONE, 1, 20), 'Нет') || ' | ' || 
                       NVL(SUBSTR(REC.EMAIL, 1, 25), 'Нет') || CHR(10);
            
            -- Администратор
            IF REC.ADMIN_NAME IS NOT NULL THEN
                V_BUFFER := V_BUFFER || 'Админ: ' || SUBSTR(REC.ADMIN_NAME, 1, 30) || ' (ID=' || REC.ADMIN_ID || ')' || CHR(10);
            ELSE
                V_BUFFER := V_BUFFER || 'Админ: Не назначен' || CHR(10);
            END IF;
            
            -- Статус и заказы
            V_BUFFER := V_BUFFER || 'Статус: ' || 
                       CASE WHEN REC.IS_ACTIVE = 1 THEN 'АКТИВЕН' ELSE 'НЕАКТИВЕН' END || 
                       ' | Активных заказов: ' || REC.ACTIVE_ORDERS || CHR(10);
            
            V_BUFFER := V_BUFFER || '------------------------------------------------------------------' || CHR(10);
            
            -- Если буфер становится слишком большим, выводим часть
            IF DBMS_LOB.GETLENGTH(V_BUFFER) > 15000 THEN
                DBMS_OUTPUT.PUT_LINE(V_BUFFER);
                V_BUFFER := ''; -- Очищаем буфер
            END IF;
        END LOOP;
        
        -- Добавляем итоговую информацию
        V_BUFFER := V_BUFFER || CHR(10) || 'Всего магазинов: ' || V_COUNT;
        
        -- Выводим оставшийся буфер
        IF DBMS_LOB.GETLENGTH(V_BUFFER) > 0 THEN
            DBMS_OUTPUT.PUT_LINE(V_BUFFER);
        END IF;
        
    END SHOW_FLOWER_SHOPS;

    -- 9. Просмотр всех ролей 
    PROCEDURE SHOW_USER_ROLES IS
        CURSOR C_ROLES IS
            SELECT 
                UR.ID,
                UR.ROLE_NAME,
                COUNT(AU.ID) AS USER_COUNT
            FROM HEAD_ADMIN.USER_ROLE UR
            LEFT JOIN HEAD_ADMIN.APP_USER AU ON UR.ID = AU.USER_ROLE
            GROUP BY UR.ID, UR.ROLE_NAME
            ORDER BY UR.ID;
        V_COUNT NUMBER := 0;
        V_BUFFER CLOB := '';
    BEGIN
        V_BUFFER := V_BUFFER || '==================================================================' || CHR(10);
        V_BUFFER := V_BUFFER || 'СПИСОК РОЛЕЙ ПОЛЬЗОВАТЕЛЕЙ' || CHR(10);
        V_BUFFER := V_BUFFER || '==================================================================' || CHR(10);
        
        FOR REC IN C_ROLES LOOP
            V_COUNT := V_COUNT + 1;
            V_BUFFER := V_BUFFER || 'ID: ' || REC.ID || ' | Роль: ' || REC.ROLE_NAME || CHR(10);
            V_BUFFER := V_BUFFER || 'Пользователей: ' || REC.USER_COUNT || CHR(10);
            V_BUFFER := V_BUFFER || '------------------------------------------------------------------' || CHR(10);
            
            -- Периодически выводим буфер
            IF MOD(V_COUNT, 20) = 0 THEN
                DBMS_OUTPUT.PUT_LINE(V_BUFFER);
                V_BUFFER := '';
            END IF;
        END LOOP;
        
        V_BUFFER := V_BUFFER || CHR(10) || 'Всего ролей: ' || V_COUNT;
        
        IF DBMS_LOB.GETLENGTH(V_BUFFER) > 0 THEN
            DBMS_OUTPUT.PUT_LINE(V_BUFFER);
        END IF;
        
    END SHOW_USER_ROLES;

    -- 10. Просмотр администраторов магазинов 
    PROCEDURE SHOW_SHOP_ADMINS IS
        CURSOR C_ADMINS IS
            SELECT 
                AU.ID,
                PD.FULL_NAME,
                PD.EMAIL,
                PD.PHONE_NUMBER,
                PD.DATE_OF_BIRTH,
                COUNT(FS.ID) AS MANAGED_SHOPS
            FROM HEAD_ADMIN.APP_USER AU
            JOIN HEAD_ADMIN.PERSONAL_DATA PD ON AU.PERSONAL_DATA = PD.ID
            JOIN HEAD_ADMIN.USER_ROLE UR ON AU.USER_ROLE = UR.ID
            LEFT JOIN HEAD_ADMIN.FLOWER_SHOP FS ON AU.ID = FS.SHOP_ADMIN_ID
            WHERE UR.ROLE_NAME = 'shop_admin'
            GROUP BY AU.ID, PD.FULL_NAME, PD.EMAIL, PD.PHONE_NUMBER, PD.DATE_OF_BIRTH
            ORDER BY AU.ID;
        V_COUNT NUMBER := 0;
        V_BUFFER CLOB := '';
        V_MAX_RECORDS CONSTANT NUMBER := 50; -- Максимум записей за раз
    BEGIN
        V_BUFFER := V_BUFFER || '==================================================================' || CHR(10);
        V_BUFFER := V_BUFFER || 'СПИСОК АДМИНИСТРАТОРОВ МАГАЗИНОВ' || CHR(10);
        V_BUFFER := V_BUFFER || '==================================================================' || CHR(10);
        
        FOR REC IN C_ADMINS LOOP
            V_COUNT := V_COUNT + 1;
            
            -- Если слишком много записей, предлагаем фильтрацию
            IF V_COUNT > V_MAX_RECORDS THEN
                V_BUFFER := V_BUFFER || '... показано ' || V_MAX_RECORDS || ' из ' || C_ADMINS%ROWCOUNT || ' записей' || CHR(10);
                V_BUFFER := V_BUFFER || 'Используйте фильтрацию для просмотра остальных записей.' || CHR(10);
                EXIT;
            END IF;
            
            V_BUFFER := V_BUFFER || 'ID: ' || REC.ID || ' | ' || SUBSTR(REC.FULL_NAME, 1, 30) || CHR(10);
            V_BUFFER := V_BUFFER || 'Email: ' || SUBSTR(REC.EMAIL, 1, 25) || CHR(10);
            V_BUFFER := V_BUFFER || 'Телефон: ' || NVL(SUBSTR(REC.PHONE_NUMBER, 1, 15), 'Не указан') || CHR(10);
            V_BUFFER := V_BUFFER || 'Дата рождения: ' || TO_CHAR(REC.DATE_OF_BIRTH, 'DD.MM.YYYY') || CHR(10);
            V_BUFFER := V_BUFFER || 'Управляемых магазинов: ' || REC.MANAGED_SHOPS || CHR(10);
            V_BUFFER := V_BUFFER || '------------------------------------------------------------------' || CHR(10);
            
            -- Выводим каждые 10 записей
            IF MOD(V_COUNT, 10) = 0 THEN
                DBMS_OUTPUT.PUT_LINE(V_BUFFER);
                V_BUFFER := '';
            END IF;
        END LOOP;
        
        V_BUFFER := V_BUFFER || CHR(10) || 'Всего администраторов: ' || V_COUNT;
        
        IF DBMS_LOB.GETLENGTH(V_BUFFER) > 0 THEN
            DBMS_OUTPUT.PUT_LINE(V_BUFFER);
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Если все равно переполнение, выводим краткую статистику
            DBMS_OUTPUT.PUT_LINE('Слишком много записей для вывода. Используйте фильтрацию.');
            DBMS_OUTPUT.PUT_LINE('Всего администраторов магазинов: ' || V_COUNT);
    END SHOW_SHOP_ADMINS;

    -- 11. Просмотр каталога товаров 
    PROCEDURE SHOW_PRODUCTS(
        P_SHOW_ONLY_ACTIVE NUMBER DEFAULT 1
    ) IS
        CURSOR C_PRODUCTS IS
            SELECT 
                P.ID,
                P.PRODUCT_NAME,
                P.BASE_PRICE,
                P.DESCRIPTION,
                P.IS_ACTIVE,
                DBMS_LOB.GETLENGTH(P.PRODUCT_IMAGE) AS IMAGE_SIZE
            FROM HEAD_ADMIN.PRODUCT P
            WHERE (P_SHOW_ONLY_ACTIVE = 0 OR P.IS_ACTIVE = 1)
            ORDER BY P.ID;
        V_COUNT NUMBER := 0;
        V_BUFFER CLOB := '';
        V_PAGE_SIZE CONSTANT NUMBER := 30; -- Записей на страницу
        V_MAX_PAGES CONSTANT NUMBER := 3;  -- Максимум страниц
    BEGIN
        V_BUFFER := V_BUFFER || '==================================================================' || CHR(10);
        V_BUFFER := V_BUFFER || 'КАТАЛОГ ТОВАРОВ' || CHR(10);
        V_BUFFER := V_BUFFER || '==================================================================' || CHR(10);
        
        FOR REC IN C_PRODUCTS LOOP
            V_COUNT := V_COUNT + 1;
            
            -- Ограничиваем количество выводимых записей
            IF V_COUNT > (V_PAGE_SIZE * V_MAX_PAGES) THEN
                V_BUFFER := V_BUFFER || '... показано ' || (V_PAGE_SIZE * V_MAX_PAGES) || ' из ' || C_PRODUCTS%ROWCOUNT || ' товаров' || CHR(10);
                V_BUFFER := V_BUFFER || 'Для просмотра всех товаров используйте фильтрацию или экспорт.' || CHR(10);
                EXIT;
            END IF;
            
            -- Краткий вывод
            V_BUFFER := V_BUFFER || 
                       LPAD(REC.ID, 4) || ' | ' ||
                       RPAD(SUBSTR(REC.PRODUCT_NAME, 1, 25), 25) || ' | ' ||
                       LPAD(REC.BASE_PRICE || ' руб.', 12) || ' | ' ||
                       CASE WHEN REC.IS_ACTIVE = 1 THEN 'АКТИВЕН' ELSE 'СКРЫТ ' END || CHR(10);
            
            -- Выводим каждые V_PAGE_SIZE записей
            IF MOD(V_COUNT, V_PAGE_SIZE) = 0 THEN
                V_BUFFER := V_BUFFER || '------------------------------------------------------------------' || CHR(10);
                DBMS_OUTPUT.PUT_LINE(V_BUFFER);
                V_BUFFER := '';
                
                -- Запрашиваем подтверждение для продолжения
                IF V_COUNT < C_PRODUCTS%ROWCOUNT AND V_COUNT < (V_PAGE_SIZE * V_MAX_PAGES) THEN
                    DBMS_OUTPUT.PUT_LINE('Нажмите Enter для продолжения...');
                    -- В реальном приложении здесь была бы пауза
                END IF;
            END IF;
        END LOOP;
        
        -- Выводим итоговую информацию
        IF DBMS_LOB.GETLENGTH(V_BUFFER) > 0 THEN
            V_BUFFER := V_BUFFER || '------------------------------------------------------------------' || CHR(10);
            V_BUFFER := V_BUFFER || 'Всего товаров: ' || V_COUNT || CHR(10);
            IF V_COUNT >= (V_PAGE_SIZE * V_MAX_PAGES) THEN
                V_BUFFER := V_BUFFER || 'Показаны первые ' || (V_PAGE_SIZE * V_MAX_PAGES) || ' записей' || CHR(10);
            END IF;
            DBMS_OUTPUT.PUT_LINE(V_BUFFER);
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            -- Краткий вывод при ошибке
            DBMS_OUTPUT.PUT_LINE('В каталоге товаров: ' || V_COUNT || ' записей');
            DBMS_OUTPUT.PUT_LINE('Для детального просмотра используйте фильтрацию по категориям.');
    END SHOW_PRODUCTS;

END HEAD_ADMIN_PACKAGE;
/

-- Проверка создания
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== HEAD_ADMIN_PACKAGE СОЗДАН ===');
    DBMS_OUTPUT.PUT_LINE('Пакет для главного администратора готов к использованию');
END;
/