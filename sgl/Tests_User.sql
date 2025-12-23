SET SERVEROUTPUT OFF;
BEGIN
    HEAD_ADMIN.USER_PACKAGE.PURGE_CART(58);
END;
/

-- Добавление товара
DECLARE
    V_CART_ITEM_ID INT;
    V_NEW_QUANTITY INT;
    V_TOTAL_ITEMS INT;
BEGIN
    HEAD_ADMIN.USER_PACKAGE.ADD_TO_CART(
        P_CART_ID => 58,
        P_PRODUCT_ID => 270286,
        P_SIZE_ID => 22,
        P_CART_ITEM_ID => V_CART_ITEM_ID,
        P_NEW_QUANTITY => V_NEW_QUANTITY,
        P_TOTAL_ITEMS => V_TOTAL_ITEMS
    );
END;
/
-- Обновление количества товара в корзине
DECLARE
    V_UPDATED_ROWS INT;
    V_CART_ITEM_ID INT := 101;
BEGIN
    HEAD_ADMIN.USER_PACKAGE.UPDATE_CART_ITEM_QUANTITY(
        P_CART_ITEM_ID => V_CART_ITEM_ID,
        P_NEW_QUANTITY => 5,
        P_UPDATED_ROWS => V_UPDATED_ROWS
    );
END;
/

-- Удаление товара из корзины
DECLARE
    V_DELETED_ROWS INT;
    V_ITEM_ID INT := 4;
BEGIN
    HEAD_ADMIN.USER_PACKAGE.DELETE_ITEM_FROM_CART(
        P_ID => V_ITEM_ID,
        P_DELETED_ROWS => V_DELETED_ROWS
    );
END;
/

-- Очистка корзины
BEGIN    
    HEAD_ADMIN.USER_PACKAGE.PURGE_CART(
        P_CART_ID => 55
    );
END;
/

-- Создание заказа 
DECLARE
    V_ORDER_ID NUMBER;
BEGIN
    HEAD_ADMIN.USER_PACKAGE.CREATE_USER_ORDER(
        P_USER_LATITUDE => 53.949036,
        P_USER_LONGITUDE => 27.601616,
--        P_USER_LATITUDE => 53.902284,
--        P_USER_LONGITUDE => 27.561831,
        P_USER_ID => 50,
        P_ADDRESS => 'Минск, ул. Широкая, 1',
        P_CART_ID => 58,
        P_ORDER_ID => V_ORDER_ID
    );
END;
/

-- Регистрация пользователя
DECLARE
    V_USER_ID NUMBER;
BEGIN
    HEAD_ADMIN.USER_PACKAGE.REGISTER_USER(
        P_FULL_NAME => 'Тест 1',
        P_EMAIL => 'test01@example.by',
        P_PHONE_NUMBER => '+375291236589',
        P_DATE_OF_BIRTH => '12-12-1984',
        P_PASSWORD => 'qwert',
        P_USER_ID => V_USER_ID
    );
END;
/

-- Получение товара по ID
DECLARE
    V_PRODUCTS HEAD_ADMIN.TABLE_PRODUCT;
    V_COUNT NUMBER;
BEGIN
    HEAD_ADMIN.USER_PACKAGE.GET_PRODUCT_BY_ID(
        P_PROD_ID => 201342,
        P_RESULT => V_PRODUCTS
    );
    
    V_COUNT := V_PRODUCTS.COUNT;
    
    IF V_COUNT > 0 THEN
        FOR i IN 1..V_COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('Товар: ' || V_PRODUCTS(i).PRODUCT_NAME || 
                               ', Цена: ' || V_PRODUCTS(i).BASE_PRICE);
        END LOOP;
    ELSE
        DBMS_OUTPUT.PUT_LINE('Товар не найден');
    END IF;
END;
/



-- Получение всех товаров
DECLARE
    V_PRODUCTS HEAD_ADMIN.TABLE_PRODUCT;
BEGIN
    HEAD_ADMIN.USER_PACKAGE.GET_ALL_PRODUCTS(
        P_RESULT => V_PRODUCTS
    );
    
    DBMS_OUTPUT.PUT_LINE('Всего товаров: ' || V_PRODUCTS.COUNT);
    FOR i IN 1..V_PRODUCTS.COUNT LOOP
        IF i <= 10 THEN
            DBMS_OUTPUT.PUT_LINE(i || '. ' || V_PRODUCTS(i).PRODUCT_NAME);
        END IF;
    END LOOP;
END;
/

-- Поиск ближайшего магазина
DECLARE
    V_NEAREST_SHOP VARCHAR2(500);
BEGIN    
    HEAD_ADMIN.USER_PACKAGE.FIND_NEAREST_SHOP(
        P_USER_LATITUDE => 53.902284,
        P_USER_LONGITUDE => 27.561831,
        P_NEAREST_SHOP => V_NEAREST_SHOP
    );
    
    DBMS_OUTPUT.PUT_LINE('Ближайший магазин: ' || V_NEAREST_SHOP);
END;
/

-- Поиск магазина по местоположению
DECLARE
    V_SHOP_ID INT;
BEGIN
    HEAD_ADMIN.USER_PACKAGE.FIND_SHOP_BY_LOCATION(
        P_USER_LATITUDE => 53.902284,
        P_USER_LONGITUDE => 27.561831,
        P_SHOP_ID => V_SHOP_ID
    );
    
    IF V_SHOP_ID IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Магазин в зоне доставки найден. ID: ' || V_SHOP_ID);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Адрес вне зоны доставки');
    END IF;
END;
/


