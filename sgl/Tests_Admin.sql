SET SERVEROUTPUT OFF;

-- Потверждение заказа
UPDATE HEAD_ADMIN.USER_ORDER SET STATUS = 'PROCESSING' WHERE ID = 61;
COMMIT;

-- Курьер забирает заказ
UPDATE HEAD_ADMIN.USER_ORDER SET STATUS = 'DELIVERING' WHERE ID = 61;
UPDATE HEAD_ADMIN.COURIER SET IS_AVAILABLE = 0 WHERE ID = 2;
COMMIT;

-- Завершение доставки
UPDATE HEAD_ADMIN.USER_ORDER SET STATUS = 'DELIVERED', DELIVERY_DATE = SYSTIMESTAMP WHERE ID = 61;
UPDATE HEAD_ADMIN.COURIER SET IS_AVAILABLE = 1 WHERE ID = 2;
COMMIT;



BEGIN    
    HEAD_ADMIN.USER_PACKAGE.PURGE_CART(
        P_CART_ID => 58
    );
END;
/

BEGIN    
    HEAD_ADMIN.SHOP_ADMIN_PACKAGE.INSERT_COURIER(
        FULL_NAME => 'Мирн Петр Анатоливич',
        EMAIL => 'dfgg@example.com',
        PHONE_NUMBER => '+375290001257',
        DATE_OF_BIRTH => '12-02-1978',
        SALARY => 1000,
        VEHICLE_TYPE => 'Автомобиль',
        SHOP_ID => 1
    );
END;
/

BEGIN    
    HEAD_ADMIN.SHOP_ADMIN_PACKAGE.UPDATE_COURIER(
        P_ID => 21,
        P_SALARY => 1200,
        P_VEHICLE_TYPE => 'Мотоцикл',
        P_IS_ACTIVE => 1,
        P_IS_AVAILABLE => 1
    );
END;
/

BEGIN
    HEAD_ADMIN.SHOP_ADMIN_PACKAGE.DELETE_COURIER(
	P_ID => 21);
END;
/

DECLARE
    V_SHOP_DATA HEAD_ADMIN.TABLE_SHOP;
BEGIN
    HEAD_ADMIN.SHOP_ADMIN_PACKAGE.GET_FLOWER_SHOP_BY_ID(
        P_SHOP_ID => 1,
        P_RESULT => V_SHOP_DATA
    );
    
    IF V_SHOP_DATA.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Магазин с ID=X не найден');
    ELSE
        FOR I IN 1..V_SHOP_DATA.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('=== Информация о магазине ===');
            DBMS_OUTPUT.PUT_LINE('ID: ' || V_SHOP_DATA(I).ID);
            DBMS_OUTPUT.PUT_LINE('Название: ' || V_SHOP_DATA(I).SHOP_NAME);
            DBMS_OUTPUT.PUT_LINE('Адрес: ' || V_SHOP_DATA(I).ADDRESS);
            DBMS_OUTPUT.PUT_LINE('Администратор магазина ID: ' || V_SHOP_DATA(I).SHOP_ADMIN);
            DBMS_OUTPUT.PUT_LINE('Время работы: ' || V_SHOP_DATA(I).OPEN_TIME || ' - ' || V_SHOP_DATA(I).CLOSE_TIME);
            DBMS_OUTPUT.PUT_LINE('Доставка: ' || V_SHOP_DATA(I).DELIVERY_START_TIME || ' - ' || V_SHOP_DATA(I).DELIVERY_END_TIME);
            DBMS_OUTPUT.PUT_LINE('Активен: ' || CASE WHEN V_SHOP_DATA(I).IS_ACTIVE = 1 THEN 'Да' ELSE 'Нет' END);
            
            IF V_SHOP_DATA(I).LOCATION IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('Локация (GEOJSON): ' || SUBSTR(V_SHOP_DATA(I).LOCATION, 1, 100));
            END IF;
        END LOOP;
    END IF;
END;
/



DECLARE
    V_SHOP_DATA HEAD_ADMIN.TABLE_SHOP;
BEGIN
    HEAD_ADMIN.SHOP_ADMIN_PACKAGE.GET_FLOWER_SHOP_BY_ADMIN(
        P_ADMIN_ID => 43,
        P_RESULT => V_SHOP_DATA
    );
    
    IF V_SHOP_DATA.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Магазин для администратора с ID=XX не найден');
    ELSE
        FOR I IN 1..V_SHOP_DATA.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('=== Информация о магазине администратора ===');
            DBMS_OUTPUT.PUT_LINE('ID: ' || V_SHOP_DATA(I).ID);
            DBMS_OUTPUT.PUT_LINE('Название: ' || V_SHOP_DATA(I).SHOP_NAME);
            DBMS_OUTPUT.PUT_LINE('Адрес: ' || V_SHOP_DATA(I).ADDRESS);
            DBMS_OUTPUT.PUT_LINE('Администратор магазина ID: ' || V_SHOP_DATA(I).SHOP_ADMIN);
            DBMS_OUTPUT.PUT_LINE('Время работы: ' || V_SHOP_DATA(I).OPEN_TIME || ' - ' || V_SHOP_DATA(I).CLOSE_TIME);
            DBMS_OUTPUT.PUT_LINE('Доставка: ' || V_SHOP_DATA(I).DELIVERY_START_TIME || ' - ' || V_SHOP_DATA(I).DELIVERY_END_TIME);
            DBMS_OUTPUT.PUT_LINE('Активен: ' || CASE WHEN V_SHOP_DATA(I).IS_ACTIVE = 1 THEN 'Да' ELSE 'Нет' END);
            
            IF V_SHOP_DATA(I).LOCATION IS NOT NULL THEN
                DBMS_OUTPUT.PUT_LINE('Локация (GEOJSON): ' || SUBSTR(V_SHOP_DATA(I).LOCATION, 1, 100));
            END IF;
        END LOOP;
    END IF;
END;
/

DECLARE
    V_COURIERS HEAD_ADMIN.TABLE_COURIER;
BEGIN
    HEAD_ADMIN.SHOP_ADMIN_PACKAGE.GET_COURIER_BY_SHOP(
        P_SHOP_ID => 1,
        P_RESULT => V_COURIERS
    );
    
    DBMS_OUTPUT.PUT_LINE('=== КУРЬЕРЫ МАГАЗИНА ===');
    DBMS_OUTPUT.PUT_LINE('Количество курьеров: ' || V_COURIERS.COUNT);
    
    IF V_COURIERS.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('В магазине нет курьеров');
    ELSE
        FOR I IN 1..V_COURIERS.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('--- Курьер #' || I || ' ---');
            DBMS_OUTPUT.PUT_LINE('ID курьера: ' || V_COURIERS(I).ID);
            DBMS_OUTPUT.PUT_LINE('ФИО: ' || V_COURIERS(I).FULL_NAME);
            DBMS_OUTPUT.PUT_LINE('Email: ' || V_COURIERS(I).EMAIL);
            DBMS_OUTPUT.PUT_LINE('Телефон: ' || V_COURIERS(I).PHONE_NUMBER);
            DBMS_OUTPUT.PUT_LINE('Дата рождения: ' || V_COURIERS(I).DATE_OF_BIRTH);
            DBMS_OUTPUT.PUT_LINE('Зарплата: ' || TO_CHAR(V_COURIERS(I).SALARY, '999,999') || ' руб.');
            DBMS_OUTPUT.PUT_LINE('Транспорт: ' || V_COURIERS(I).VEHICLE_TYPE);
            DBMS_OUTPUT.PUT_LINE('Активен: ' || CASE WHEN V_COURIERS(I).IS_ACTIVE = 1 THEN 'Да' ELSE 'Нет' END);
            DBMS_OUTPUT.PUT_LINE('Доступен: ' || CASE WHEN V_COURIERS(I).IS_AVAILABLE = 1 THEN 'Да' ELSE 'Нет' END);
        END LOOP;
    END IF;
END;
/

DECLARE
    V_COURIERS HEAD_ADMIN.TABLE_COURIER;
BEGIN
    HEAD_ADMIN.SHOP_ADMIN_PACKAGE.GET_COURIER_BY_ID(
        P_COURIER_ID => 1,
        P_RESULT => V_COURIERS
    );
    
    IF V_COURIERS.COUNT = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Курьер с ID=X не найден');
    ELSE
        FOR I IN 1..V_COURIERS.COUNT LOOP
            DBMS_OUTPUT.PUT_LINE('=== ИНФОРМАЦИЯ О КУРЬЕРЕ ===');
            DBMS_OUTPUT.PUT_LINE('ID курьера: ' || V_COURIERS(I).ID);
            DBMS_OUTPUT.PUT_LINE('ФИО: ' || V_COURIERS(I).FULL_NAME);
            DBMS_OUTPUT.PUT_LINE('Email: ' || V_COURIERS(I).EMAIL);
            DBMS_OUTPUT.PUT_LINE('Телефон: ' || V_COURIERS(I).PHONE_NUMBER);
            DBMS_OUTPUT.PUT_LINE('Дата рождения: ' || V_COURIERS(I).DATE_OF_BIRTH);
            DBMS_OUTPUT.PUT_LINE('Зарплата: ' || TO_CHAR(V_COURIERS(I).SALARY, '999,999') || ' руб.');
            DBMS_OUTPUT.PUT_LINE('Транспорт: ' || V_COURIERS(I).VEHICLE_TYPE);
            DBMS_OUTPUT.PUT_LINE('Статус активности: ' || CASE WHEN V_COURIERS(I).IS_ACTIVE = 1 THEN 'Активен' ELSE 'Неактивен' END);
            DBMS_OUTPUT.PUT_LINE('Статус доступности: ' || CASE WHEN V_COURIERS(I).IS_AVAILABLE = 1 THEN 'Доступен для заказов' ELSE 'Занят' END);
        END LOOP;
    END IF;
END;
/
