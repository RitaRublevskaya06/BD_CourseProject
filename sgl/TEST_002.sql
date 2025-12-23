-- ПРОВЕРКА АКТИВНЫХ МАГАЗИНОВ
DECLARE
    V_USER_LOCATION SDO_GEOMETRY;
    V_SHOP_FOUND BOOLEAN := FALSE;
    V_SHOP_ID NUMBER;
    V_SHOP_NAME VARCHAR2(100);
    V_ADDRESS VARCHAR2(200);
    V_IS_ACTIVE NUMBER;
    V_LOCATION_WKT VARCHAR2(1000);
    V_COVERAGE_WKT VARCHAR2(1000);
BEGIN
    V_USER_LOCATION := SDO_GEOMETRY(
        2001,
        4326,
        SDO_POINT_TYPE(27.561831, 53.902284, NULL),
        NULL,
        NULL
    );
    
    DBMS_OUTPUT.PUT_LINE('=== ПРОВЕРКА МАГАЗИНОВ ДЛЯ КООРДИНАТ: 53.902284, 27.561831 ===');
    DBMS_OUTPUT.PUT_LINE('');
    
    FOR shop_rec IN (
        SELECT 
            ID,
            SHOP_NAME,
            ADDRESS,
            IS_ACTIVE,
            LOCATION,
            COVERAGE_AREA
        FROM HEAD_ADMIN.FLOWER_SHOP
        WHERE IS_ACTIVE = 1
        ORDER BY ID
    ) LOOP
        V_SHOP_ID := shop_rec.ID;
        V_SHOP_NAME := shop_rec.SHOP_NAME;
        V_ADDRESS := shop_rec.ADDRESS;
        V_IS_ACTIVE := shop_rec.IS_ACTIVE;
        
        DBMS_OUTPUT.PUT_LINE('Магазин ID: ' || V_SHOP_ID);
        DBMS_OUTPUT.PUT_LINE('Название: ' || V_SHOP_NAME);
        DBMS_OUTPUT.PUT_LINE('Адрес: ' || V_ADDRESS);
        
        BEGIN
            DECLARE
                V_IS_IN_AREA VARCHAR2(5);
            BEGIN
                SELECT SDO_RELATE(shop_rec.COVERAGE_AREA, V_USER_LOCATION, 'MASK=ANYINTERACT')
                INTO V_IS_IN_AREA
                FROM DUAL;
                
                IF V_IS_IN_AREA = 'TRUE' THEN
                    DBMS_OUTPUT.PUT_LINE('Координаты ВХОДЯТ в зону доставки этого магазина');
                    V_SHOP_FOUND := TRUE;
                ELSE
                    DBMS_OUTPUT.PUT_LINE('Координаты НЕ входят в зону доставки');
                END IF;
            EXCEPTION
                WHEN OTHERS THEN
                    DBMS_OUTPUT.PUT_LINE('Ошибка проверки: ' || SQLERRM);
            END;
            
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка при получении WKT: ' || SQLERRM);
        END;
        
        DBMS_OUTPUT.PUT_LINE('---');
    END LOOP;
    
    IF NOT V_SHOP_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('ВНИМАНИЕ: Ни один магазин не обслуживает эти координаты!');
        DBMS_OUTPUT.PUT_LINE('   Нужно расширить зоны доставки магазинов.');
    END IF;
END;
/




