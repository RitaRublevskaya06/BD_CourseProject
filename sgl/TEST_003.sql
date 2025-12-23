-- ============================================
-- ТЕСТ С ПУСТОЙ КОРЗИНОЙ 56 (Волкова Ольга)
-- ============================================

-- 1. Очистим корзину (на всякий случай)
BEGIN
    HEAD_ADMIN.USER_PACKAGE.PURGE_CART(56);
    DBMS_OUTPUT.PUT_LINE('Корзина 56 очищена');
END;
/

-- 2. Добавим товар
DECLARE
    V_CART_ITEM_ID INT;
    V_NEW_QUANTITY INT;
    V_TOTAL_ITEMS INT;
BEGIN
    HEAD_ADMIN.USER_PACKAGE.ADD_TO_CART(
        P_CART_ID => 56,
        P_PRODUCT_ID => 201341,
        P_SIZE_ID => 21,
        P_CART_ITEM_ID => V_CART_ITEM_ID,
        P_NEW_QUANTITY => V_NEW_QUANTITY,
        P_TOTAL_ITEMS => V_TOTAL_ITEMS
    );
END;
/


-- ПРОСТОЙ ТЕСТ СОЗДАНИЯ ЗАКАЗА
DECLARE
    V_ORDER_ID NUMBER;
BEGIN
    HEAD_ADMIN.USER_PACKAGE.CREATE_USER_ORDER(
        P_USER_LATITUDE => 53.902284,
        P_USER_LONGITUDE => 27.561831,
        P_USER_ID => 48,
        P_ADDRESS => 'Минск, пр. Независимости, 1',
        P_CART_ID => 56,
        P_ORDER_ID => V_ORDER_ID
    );
    
    IF V_ORDER_ID IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Заказ создан. ID: ' || V_ORDER_ID);
    END IF;
END;
/


-- Тестируем FIND_SHOP_BY_LOCATION
DECLARE
    V_SHOP_ID NUMBER;
BEGIN
    HEAD_ADMIN.USER_PACKAGE.FIND_SHOP_BY_LOCATION(
        P_USER_LATITUDE => 53.902284,
        P_USER_LONGITUDE => 27.561831,
        P_SHOP_ID => V_SHOP_ID
    );
    
    IF V_SHOP_ID IS NOT NULL THEN
        DBMS_OUTPUT.PUT_LINE('Результат: магазин найден, ID=' || V_SHOP_ID);
    ELSE
        DBMS_OUTPUT.PUT_LINE('Результат: магазин не найден');
    END IF;
END;
/