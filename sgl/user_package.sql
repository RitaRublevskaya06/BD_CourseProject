-- Спецификация пакета
CREATE OR REPLACE PACKAGE HEAD_ADMIN.USER_PACKAGE AS
    -- Регистрация
    PROCEDURE INSERT_PERSONAL_DATA(
        P_FULL_NAME PERSONAL_DATA.FULL_NAME%TYPE,
        P_EMAIL PERSONAL_DATA.EMAIL%TYPE,
        P_PHONE_NUMBER PERSONAL_DATA.PHONE_NUMBER%TYPE,
        P_DATE_OF_BIRTH IN VARCHAR2,
        P_DATA_ID OUT PERSONAL_DATA.ID%TYPE
    );
    
    PROCEDURE REGISTER_USER(
        P_FULL_NAME PERSONAL_DATA.FULL_NAME%TYPE,
        P_EMAIL PERSONAL_DATA.EMAIL%TYPE,
        P_PHONE_NUMBER PERSONAL_DATA.PHONE_NUMBER%TYPE,
        P_DATE_OF_BIRTH IN VARCHAR2,
        P_PASSWORD IN VARCHAR2,
        P_USER_ID OUT APP_USER.ID%TYPE
    );
    
    -- Товары
    PROCEDURE GET_PRODUCT_BY_ID(
        P_PROD_ID INT,
        P_RESULT OUT TABLE_PRODUCT
    );
    
    PROCEDURE GET_ALL_PRODUCTS(
        P_RESULT OUT TABLE_PRODUCT
    );
    
    PROCEDURE GET_PRODUCTS_PAGE(
        P_PAGE_NUMBER INT,
        P_PAGE_SIZE INT,
        P_RESULT OUT TABLE_PRODUCT
    );
    
    -- Spatial функции
    PROCEDURE FIND_NEAREST_SHOP(
        P_USER_LATITUDE NUMBER,
        P_USER_LONGITUDE NUMBER,
        P_NEAREST_SHOP OUT VARCHAR2
    );
    
    PROCEDURE FIND_SHOP_BY_LOCATION(
        P_USER_LATITUDE NUMBER,
        P_USER_LONGITUDE NUMBER,
        P_SHOP_ID OUT INT
    );
    
    -- Корзина
    PROCEDURE ADD_TO_CART(
        P_CART_ID INT,
        P_PRODUCT_ID INT,
        P_SIZE_ID INT,
        P_CART_ITEM_ID OUT INT, 
        P_NEW_QUANTITY OUT INT,   
        P_TOTAL_ITEMS OUT INT
    );
    
    PROCEDURE UPDATE_CART_ITEM_QUANTITY(
        P_CART_ITEM_ID INT,
        P_NEW_QUANTITY INT,
        P_UPDATED_ROWS OUT INT
    );
    
    PROCEDURE DELETE_ITEM_FROM_CART(
        P_ID INT,
        P_DELETED_ROWS OUT INT);
    PROCEDURE PURGE_CART(P_CART_ID INT);
    
    -- Заказы
    PROCEDURE CREATE_USER_ORDER(
        P_USER_LATITUDE NUMBER,
        P_USER_LONGITUDE NUMBER,
        P_USER_ID INT,
        P_ADDRESS NVARCHAR2,
        P_CART_ID INT,
        P_ORDER_ID OUT NUMBER
    );
    
    PROCEDURE GET_ORDERS_BY_USER(
        P_USER_ID INT,
        P_RESULT OUT TABLE_ORDER
    );
    
    PROCEDURE GET_ITEMS_BY_ORDER(
        P_ORDER_ID INT,
        P_RESULT OUT TABLE_ORDER_ITEM
    );
    
    -- Курьер
    PROCEDURE GET_COURIER_FOR_ORDER(
        P_SHOP_ID INT,
        P_COURIER_ID OUT INT
    );
    
END USER_PACKAGE;
/

-- Тело пакета
CREATE OR REPLACE PACKAGE BODY HEAD_ADMIN.USER_PACKAGE AS
    
    -- 1. Вставка персональных данных
    PROCEDURE INSERT_PERSONAL_DATA(
        P_FULL_NAME PERSONAL_DATA.FULL_NAME%TYPE,
        P_EMAIL PERSONAL_DATA.EMAIL%TYPE,
        P_PHONE_NUMBER PERSONAL_DATA.PHONE_NUMBER%TYPE,
        P_DATE_OF_BIRTH IN VARCHAR2,
        P_DATA_ID OUT PERSONAL_DATA.ID%TYPE
    ) IS
    BEGIN
        INSERT INTO PERSONAL_DATA (FULL_NAME, EMAIL, PHONE_NUMBER, DATE_OF_BIRTH)
        VALUES (P_FULL_NAME, P_EMAIL, P_PHONE_NUMBER, TO_DATE(P_DATE_OF_BIRTH, 'DD-MM-YYYY'))
        RETURNING ID INTO P_DATA_ID;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Персональные данные успешно добавлены. ID: ' || P_DATA_ID);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка вставки персональных данных: ' || SQLERRM);
            P_DATA_ID := NULL;
    END INSERT_PERSONAL_DATA;
    
    -- 2. Регистрация пользователя
    PROCEDURE REGISTER_USER(
        P_FULL_NAME PERSONAL_DATA.FULL_NAME%TYPE,
        P_EMAIL PERSONAL_DATA.EMAIL%TYPE,
        P_PHONE_NUMBER PERSONAL_DATA.PHONE_NUMBER%TYPE,
        P_DATE_OF_BIRTH IN VARCHAR2,
        P_PASSWORD IN VARCHAR2,
        P_USER_ID OUT APP_USER.ID%TYPE
    ) IS
        V_USER_ROLE_ID USER_ROLE.ID%TYPE;
        V_USER_DATA_ID PERSONAL_DATA.ID%TYPE;
        V_PASSWORD_HASH VARCHAR2(64);
    BEGIN
        SELECT ID INTO V_USER_ROLE_ID 
        FROM USER_ROLE 
        WHERE ROLE_NAME = 'user';
        
        V_PASSWORD_HASH := HEAD_ADMIN.SIMPLE_PASSWORD_HASH(P_PASSWORD);
        
        INSERT_PERSONAL_DATA(
            P_FULL_NAME => P_FULL_NAME, 
            P_EMAIL => P_EMAIL, 
            P_PHONE_NUMBER => P_PHONE_NUMBER,
            P_DATE_OF_BIRTH => P_DATE_OF_BIRTH,
            P_DATA_ID => V_USER_DATA_ID
        );
        
        IF V_USER_DATA_ID IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: не удалось создать персональные данные');
            P_USER_ID := NULL;
            RETURN;
        END IF;
        
        INSERT INTO APP_USER (PASSWORD_HASH, USER_ROLE, PERSONAL_DATA)
        VALUES (V_PASSWORD_HASH, V_USER_ROLE_ID, V_USER_DATA_ID)
        RETURNING ID INTO P_USER_ID;

        INSERT INTO CART (USER_ID) VALUES (P_USER_ID);
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Пользователь успешно зарегистрирован. ID: ' || P_USER_ID);
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка: роль "user" не найдена. Сначала создайте роли.');
            P_USER_ID := NULL;
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка регистрации пользователя: ' || SQLERRM);
            P_USER_ID := NULL;
    END REGISTER_USER;
    
    -- 3. Получение товара по ID
    PROCEDURE GET_PRODUCT_BY_ID(
        P_PROD_ID INT,
        P_RESULT OUT TABLE_PRODUCT
    ) IS
    BEGIN
        SELECT RECORD_PRODUCT(
                       ID,
                       PRODUCT_NAME,
                       BASE_PRICE,
                       DESCRIPTION,
                       PRODUCT_IMAGE
                   ) BULK COLLECT
        INTO P_RESULT
        FROM PRODUCT
        WHERE ID = P_PROD_ID AND IS_ACTIVE = 1;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_RESULT := TABLE_PRODUCT();
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка получения товара: ' || SQLERRM);
            P_RESULT := TABLE_PRODUCT();
    END GET_PRODUCT_BY_ID;
    
    -- 4. Получение всех товаров
    PROCEDURE GET_ALL_PRODUCTS(
        P_RESULT OUT TABLE_PRODUCT
    ) IS
    BEGIN
        SELECT RECORD_PRODUCT(
                       ID,
                       PRODUCT_NAME,
                       BASE_PRICE,
                       DESCRIPTION,
                       PRODUCT_IMAGE
                   ) BULK COLLECT
        INTO P_RESULT
        FROM PRODUCT
        WHERE IS_ACTIVE = 1
        ORDER BY PRODUCT_NAME;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка получения товаров: ' || SQLERRM);
            P_RESULT := TABLE_PRODUCT();
    END GET_ALL_PRODUCTS;
    
    -- 5. Постраничный вывод товаров
    PROCEDURE GET_PRODUCTS_PAGE(
        P_PAGE_NUMBER INT,
        P_PAGE_SIZE INT,
        P_RESULT OUT TABLE_PRODUCT
    ) IS
        V_START_INDEX INT;
        V_END_INDEX INT;
    BEGIN
        IF P_PAGE_NUMBER <= 0 OR P_PAGE_SIZE <= 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: номер страницы и размер страницы должны быть больше 0');
            P_RESULT := TABLE_PRODUCT();
            RETURN;
        END IF;
        
        V_START_INDEX := (P_PAGE_NUMBER - 1) * P_PAGE_SIZE + 1;
        V_END_INDEX := P_PAGE_NUMBER * P_PAGE_SIZE;
        
        FOR R IN (
            SELECT *
            FROM (
                SELECT P.*, 
                       ROW_NUMBER() OVER (ORDER BY ID) AS ROW_NUM
                FROM PRODUCT P
                WHERE P.IS_ACTIVE = 1
            )
            WHERE ROW_NUM >= V_START_INDEX
              AND ROW_NUM <= V_END_INDEX
        ) LOOP
            P_RESULT.EXTEND;
            P_RESULT(P_RESULT.LAST) := RECORD_PRODUCT(
                R.ID,
                R.PRODUCT_NAME,
                R.BASE_PRICE,
                R.DESCRIPTION,
                R.PRODUCT_IMAGE
            );
        END LOOP;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка постраничного вывода товаров: ' || SQLERRM);
            P_RESULT := TABLE_PRODUCT();
    END GET_PRODUCTS_PAGE;
    
    -- 6. Поиск ближайшего магазина
    PROCEDURE FIND_NEAREST_SHOP(
        P_USER_LATITUDE NUMBER,
        P_USER_LONGITUDE NUMBER,
        P_NEAREST_SHOP OUT VARCHAR2
    ) IS
        V_USER_LOCATION SDO_GEOMETRY;
    BEGIN
        V_USER_LOCATION := SDO_GEOMETRY(
            2001,
            4326,
            SDO_POINT_TYPE(P_USER_LONGITUDE, P_USER_LATITUDE, NULL),
            NULL,
            NULL
        );

        SELECT FS.SHOP_NAME || ' - ' || FS.ADDRESS
        INTO P_NEAREST_SHOP
        FROM FLOWER_SHOP FS
        WHERE FS.IS_ACTIVE = 1
          AND SDO_NN(FS.LOCATION, V_USER_LOCATION, 'SDO_NUM_RES=1', 1) = 'TRUE';

        COMMIT;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_NEAREST_SHOP := 'Ближайший магазин не найден';
        WHEN OTHERS THEN
            P_NEAREST_SHOP := 'Ошибка поиска: ' || SQLERRM;
    END FIND_NEAREST_SHOP;
    
    -- 7. Поиск магазина по местоположению
    PROCEDURE FIND_SHOP_BY_LOCATION(
        P_USER_LATITUDE NUMBER,
        P_USER_LONGITUDE NUMBER,
        P_SHOP_ID OUT INT
    ) IS
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Поиск магазина для: ' || P_USER_LATITUDE || ', ' || P_USER_LONGITUDE);
        
--        -- ВАРИАНТ 1: Всегда возвращаем магазин ID=1 (для тестирования)
--        P_SHOP_ID := 1;
--        DBMS_OUTPUT.PUT_LINE('Выбран магазин ID=' || P_SHOP_ID);
--        
        -- ВАРИАНТ 2: Если нужно, можно раскомментировать реальную логику
        
        -- Простой поиск первого активного магазина
        BEGIN
            SELECT ID INTO P_SHOP_ID
            FROM FLOWER_SHOP
            WHERE IS_ACTIVE = 1
              AND ROWNUM = 1;
            
            DBMS_OUTPUT.PUT_LINE('Найден активный магазин ID=' || P_SHOP_ID);
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                DBMS_OUTPUT.PUT_LINE('Нет активных магазинов');
                P_SHOP_ID := NULL;
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
                P_SHOP_ID := NULL;
        END;
    
          
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка FIND_SHOP_BY_LOCATION: ' || SQLERRM);
            P_SHOP_ID := NULL;
    END FIND_SHOP_BY_LOCATION;
    
    -- 8. Добавление товара в корзину
    PROCEDURE ADD_TO_CART(
        P_CART_ID IN INT,
        P_PRODUCT_ID IN INT,
        P_SIZE_ID IN INT,
        P_CART_ITEM_ID OUT INT,
        P_NEW_QUANTITY OUT INT,
        P_TOTAL_ITEMS OUT INT
    ) IS
        V_ITEM_INFO_ID INT;
        V_EXISTING_ID INT;
        V_TOTAL_QUANTITY INT;
        V_CURRENT_QUANTITY INT := 1;
    BEGIN
        P_CART_ITEM_ID := NULL;
        P_NEW_QUANTITY := 0;
        P_TOTAL_ITEMS := 0;
        
        BEGIN
            SELECT ID INTO V_ITEM_INFO_ID
            FROM PRODUCT_ITEM_INFO
            WHERE PRODUCT_ID = P_PRODUCT_ID AND SIZE_ID = P_SIZE_ID;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO PRODUCT_ITEM_INFO (PRODUCT_ID, SIZE_ID)
                VALUES (P_PRODUCT_ID, P_SIZE_ID)
                RETURNING ID INTO V_ITEM_INFO_ID;
        END;

        SELECT NVL(SUM(QUANTITY), 0) INTO V_TOTAL_QUANTITY
        FROM CART_ITEM
        WHERE CART_ID = P_CART_ID;
        
        IF V_TOTAL_QUANTITY >= 10 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: максимальное количество товаров в корзине - 10');
            P_TOTAL_ITEMS := V_TOTAL_QUANTITY;
            RETURN;
        END IF;

        BEGIN
            SELECT ID, QUANTITY INTO V_EXISTING_ID, V_CURRENT_QUANTITY
            FROM CART_ITEM
            WHERE CART_ID = P_CART_ID AND ITEM_INFO_ID = V_ITEM_INFO_ID;
            
            UPDATE CART_ITEM
            SET QUANTITY = QUANTITY + 1
            WHERE ID = V_EXISTING_ID
            RETURNING QUANTITY INTO P_NEW_QUANTITY;
            
            P_CART_ITEM_ID := V_EXISTING_ID;
            
            DBMS_OUTPUT.PUT_LINE('Увеличено количество существующего товара');
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                INSERT INTO CART_ITEM (CART_ID, ITEM_INFO_ID, QUANTITY)
                VALUES (P_CART_ID, V_ITEM_INFO_ID, 1)
                RETURNING ID, QUANTITY INTO P_CART_ITEM_ID, P_NEW_QUANTITY;
                
                DBMS_OUTPUT.PUT_LINE('Добавлен новый товар в корзину');
        END;
        
        SELECT NVL(SUM(QUANTITY), 0) INTO P_TOTAL_ITEMS
        FROM CART_ITEM
        WHERE CART_ID = P_CART_ID;
        
        COMMIT;
        
        DBMS_OUTPUT.PUT_LINE('Товар добавлен в корзину. ID элемента: ' || P_CART_ITEM_ID);
        DBMS_OUTPUT.PUT_LINE('Количество данного товара: ' || P_NEW_QUANTITY);
        DBMS_OUTPUT.PUT_LINE('Всего товаров в корзине: ' || P_TOTAL_ITEMS);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка добавления в корзину: ' || SQLERRM);
            P_CART_ITEM_ID := NULL;
            P_NEW_QUANTITY := 0;
            P_TOTAL_ITEMS := 0;
    END ADD_TO_CART;
    
    -- 9. Обновление количества товара в корзине
    PROCEDURE UPDATE_CART_ITEM_QUANTITY(
        P_CART_ITEM_ID IN INT,
        P_NEW_QUANTITY IN INT,
        P_UPDATED_ROWS OUT INT
    ) IS
        V_EXISTS INT;
    BEGIN
        P_UPDATED_ROWS := 0;
        
        SELECT COUNT(*) INTO V_EXISTS
        FROM CART_ITEM
        WHERE ID = P_CART_ITEM_ID;
        
        IF V_EXISTS = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: элемент корзины не найден');
            RETURN;
        END IF;
        
        IF P_NEW_QUANTITY <= 0 THEN
            DELETE FROM CART_ITEM WHERE ID = P_CART_ITEM_ID;
            P_UPDATED_ROWS := SQL%ROWCOUNT;
            DBMS_OUTPUT.PUT_LINE('Товар удален из корзины. Удалено строк: ' || P_UPDATED_ROWS);
        ELSE
            UPDATE CART_ITEM
            SET QUANTITY = P_NEW_QUANTITY
            WHERE ID = P_CART_ITEM_ID;
            P_UPDATED_ROWS := SQL%ROWCOUNT;
            DBMS_OUTPUT.PUT_LINE('Количество обновлено до ' || P_NEW_QUANTITY);
            DBMS_OUTPUT.PUT_LINE('Обновлено строк: ' || P_UPDATED_ROWS);
        END IF;
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка обновления корзины: ' || SQLERRM);
            P_UPDATED_ROWS := 0;
    END UPDATE_CART_ITEM_QUANTITY;
    
    -- 10. Удаление товара из корзины (с OUT параметром)
    PROCEDURE DELETE_ITEM_FROM_CART(
        P_ID IN INT,
        P_DELETED_ROWS OUT INT
    ) IS
        V_COUNT INT;
        V_PRODUCT_NAME VARCHAR2(100);
        V_QUANTITY INT;
    BEGIN
        P_DELETED_ROWS := 0;
        
        BEGIN
            SELECT P.PRODUCT_NAME, CI.QUANTITY 
            INTO V_PRODUCT_NAME, V_QUANTITY
            FROM CART_ITEM CI
            JOIN PRODUCT_ITEM_INFO PII ON CI.ITEM_INFO_ID = PII.ID
            JOIN PRODUCT P ON PII.PRODUCT_ID = P.ID
            WHERE CI.ID = P_ID;
            
            DBMS_OUTPUT.PUT_LINE('Удаляем товар: ' || V_PRODUCT_NAME || ', количество: ' || V_QUANTITY);
            
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                V_PRODUCT_NAME := '[неизвестный товар]';
                V_QUANTITY := 0;
        END;
        
        SELECT COUNT(*) INTO V_COUNT 
        FROM CART_ITEM WHERE ID = P_ID;

        IF V_COUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: товар не найден в корзине');
            RETURN;
        END IF;
        
        DELETE FROM CART_ITEM WHERE ID = P_ID;
        P_DELETED_ROWS := SQL%ROWCOUNT;
        
        COMMIT;
        DBMS_OUTPUT.PUT_LINE('Товар "' || V_PRODUCT_NAME || '" удален из корзины. Удалено строк: ' || P_DELETED_ROWS);
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка удаления из корзины: ' || SQLERRM);
            P_DELETED_ROWS := 0;
    END DELETE_ITEM_FROM_CART;
    
    -- 11. Очистка корзины (осталась процедурой)
    PROCEDURE PURGE_CART(P_CART_ID INT) IS
        V_COUNT INT;
    BEGIN
        SELECT COUNT(*) INTO V_COUNT 
        FROM CART_ITEM 
        WHERE CART_ID = P_CART_ID;
        
        IF V_COUNT > 0 THEN
            DELETE FROM CART_ITEM WHERE CART_ID = P_CART_ID;
            DBMS_OUTPUT.PUT_LINE('Корзина очищена. Удалено товаров: ' || V_COUNT);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Корзина уже пуста');
        END IF;
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка очистки корзины: ' || SQLERRM);
    END PURGE_CART;
    
    -- 12. Получение курьера для заказа (теперь процедура)
    PROCEDURE GET_COURIER_FOR_ORDER(
        P_SHOP_ID INT,
        P_COURIER_ID OUT INT
    ) IS
    BEGIN
        SELECT C.ID
        INTO P_COURIER_ID
        FROM COURIER C
        LEFT JOIN USER_ORDER UO ON UO.COURIER_ID = C.ID 
            AND TRUNC(UO.ORDER_DATE) = TRUNC(SYSDATE)
        WHERE C.FLOWER_SHOP_ID = P_SHOP_ID
          AND C.IS_ACTIVE = 1
          AND C.IS_AVAILABLE = 1
        GROUP BY C.ID
        ORDER BY COUNT(UO.ID)
        FETCH FIRST 1 ROWS ONLY;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            P_COURIER_ID := NULL;
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка поиска курьера: ' || SQLERRM);
            P_COURIER_ID := NULL;
    END GET_COURIER_FOR_ORDER;
    
    -- 13. Создание заказа пользователя (теперь процедура)
     PROCEDURE CREATE_USER_ORDER(
        P_USER_LATITUDE NUMBER,
        P_USER_LONGITUDE NUMBER,
        P_USER_ID INT,
        P_ADDRESS NVARCHAR2,
        P_CART_ID INT,
        P_ORDER_ID OUT NUMBER
    ) IS
        V_SHOP_ID INT;
        V_COURIER_ID INT;
        V_ORDER_NUMBER VARCHAR2(50);
        V_TOTAL_AMOUNT NUMBER(10, 2) := 0;
    BEGIN
        DBMS_OUTPUT.PUT_LINE('Начало создания заказа');
        
        FIND_SHOP_BY_LOCATION(P_USER_LATITUDE, P_USER_LONGITUDE, V_SHOP_ID);
        
        IF V_SHOP_ID IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: не найден магазин');
            P_ORDER_ID := NULL;
            RETURN;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('Магазин: ID=' || V_SHOP_ID);
        
        GET_COURIER_FOR_ORDER(V_SHOP_ID, V_COURIER_ID);
        
        IF V_COURIER_ID IS NULL THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: нет доступных курьеров');
            P_ORDER_ID := NULL;
            RETURN;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('Курьер: ID=' || V_COURIER_ID);
        
        SELECT 'ORD-' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '-' || 
               TO_CHAR(DBMS_RANDOM.VALUE(100000, 999999), '999999')
        INTO V_ORDER_NUMBER
        FROM DUAL;
        
        DBMS_OUTPUT.PUT_LINE('Номер заказа: ' || V_ORDER_NUMBER);
        
        SELECT SUM(ROUND(P.BASE_PRICE * SC.MARKUP * CI.QUANTITY, 2))
        INTO V_TOTAL_AMOUNT
        FROM CART_ITEM CI
        JOIN PRODUCT_ITEM_INFO PII ON CI.ITEM_INFO_ID = PII.ID
        JOIN PRODUCT P ON PII.PRODUCT_ID = P.ID
        JOIN SIZE_CATEGORY SC ON PII.SIZE_ID = SC.ID
        WHERE CI.CART_ID = P_CART_ID;
        
        IF V_TOTAL_AMOUNT IS NULL OR V_TOTAL_AMOUNT <= 0 THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка: корзина пуста');
            P_ORDER_ID := NULL;
            RETURN;
        END IF;
        
        DBMS_OUTPUT.PUT_LINE('Сумма заказа: ' || V_TOTAL_AMOUNT || ' руб.');
        
        DECLARE
            V_DELIVERY_LOC SDO_GEOMETRY;
        BEGIN
            V_DELIVERY_LOC := SDO_GEOMETRY(
                2001,
                4326,
                SDO_POINT_TYPE(P_USER_LONGITUDE, P_USER_LATITUDE, NULL),
                NULL,
                NULL
            );
            
            INSERT INTO USER_ORDER (
                ORDER_NUMBER, USER_ID, FLOWER_SHOP_ID, 
                DELIVERY_ADDRESS, DELIVERY_LOCATION,
                COURIER_ID, TOTAL_AMOUNT, STATUS, ORDER_DATE
            ) VALUES (
                V_ORDER_NUMBER, P_USER_ID, V_SHOP_ID,
                P_ADDRESS, V_DELIVERY_LOC,
                V_COURIER_ID, V_TOTAL_AMOUNT, 'NEW', SYSTIMESTAMP
            ) RETURNING ID INTO P_ORDER_ID;
        END;
        
        DBMS_OUTPUT.PUT_LINE('Заказ создан ID=' || P_ORDER_ID);
        
        UPDATE COURIER
        SET IS_AVAILABLE = 0
        WHERE ID = V_COURIER_ID;
        
        COMMIT;
        
--        DBMS_OUTPUT.PUT_LINE('Заказ успешно создан');
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            DBMS_OUTPUT.PUT_LINE('Ошибка создания заказа: ' || SQLERRM);
            P_ORDER_ID := NULL;
    END CREATE_USER_ORDER;
    
    -- 14. Получение заказов пользователя (теперь процедура)
    PROCEDURE GET_ORDERS_BY_USER(
        P_USER_ID INT,
        P_RESULT OUT TABLE_ORDER
    ) IS
    BEGIN
        SELECT RECORD_ORDER(
                       UO.ID,
                       UO.ORDER_NUMBER,
                       TO_CHAR(UO.ORDER_DATE, 'DD.MM.YYYY HH24:MI'),
                       UO.USER_ID,
                       UO.DELIVERY_ADDRESS,
                       UO.STATUS,
                       UO.TOTAL_AMOUNT,
                       FS.SHOP_NAME
                   ) BULK COLLECT
        INTO P_RESULT
        FROM USER_ORDER UO
        JOIN FLOWER_SHOP FS ON UO.FLOWER_SHOP_ID = FS.ID
        WHERE UO.USER_ID = P_USER_ID
        ORDER BY UO.ORDER_DATE DESC;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка получения заказов: ' || SQLERRM);
            P_RESULT := TABLE_ORDER();
    END GET_ORDERS_BY_USER;
    
    -- 15. Получение товаров в заказе (теперь процедура)
    PROCEDURE GET_ITEMS_BY_ORDER(
        P_ORDER_ID INT,
        P_RESULT OUT TABLE_ORDER_ITEM
    ) IS
    BEGIN
        SELECT RECORD_ORDER_ITEM(
                       OI.ID,
                       OI.ORDER_ID,
                       P.ID,
                       P.PRODUCT_NAME,
                       SC.SIZE_NAME,
                       OI.UNIT_PRICE,
                       OI.QUANTITY,
                       OI.SUBTOTAL
                   ) BULK COLLECT
        INTO P_RESULT
        FROM ORDER_ITEM OI
        JOIN PRODUCT_ITEM_INFO PII ON OI.ITEM_INFO_ID = PII.ID
        JOIN PRODUCT P ON PII.PRODUCT_ID = P.ID
        JOIN SIZE_CATEGORY SC ON PII.SIZE_ID = SC.ID
        WHERE OI.ORDER_ID = P_ORDER_ID
        ORDER BY OI.ID;

    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка получения товаров заказа: ' || SQLERRM);
            P_RESULT := TABLE_ORDER_ITEM();
    END GET_ITEMS_BY_ORDER;

END USER_PACKAGE;
/

-- Проверка создания
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== USER_PACKAGE СОЗДАН ===');
    DBMS_OUTPUT.PUT_LINE('Готов к использованию');
END;
/