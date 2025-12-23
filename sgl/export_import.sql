-- 1. Процедура экспорта товаров в JSON
CREATE OR REPLACE PROCEDURE HEAD_ADMIN.EXPORT_PRODUCTS_TO_JSON(
    p_file_name VARCHAR2
) IS
    v_file        UTL_FILE.FILE_TYPE;
    v_batch_size  CONSTANT NUMBER := 5000;
    v_total_count NUMBER := 0;
    v_start_date  DATE;
    v_end_date    DATE;
    
    -- Используем курсор с преобразованием числа в строку с точкой
    CURSOR c_products IS
        SELECT 
            ID,
            PRODUCT_NAME,
            -- Заменяем запятую на точку для JSON
            REPLACE(TO_CHAR(BASE_PRICE, 'FM9999999990D00', 'NLS_NUMERIC_CHARACTERS=''. '''), ',', '.') as BASE_PRICE_STR,
            DESCRIPTION,
            IS_ACTIVE
        FROM HEAD_ADMIN.PRODUCT
        ORDER BY ID;
    
    TYPE t_product_tab IS TABLE OF c_products%ROWTYPE;
    v_products t_product_tab;
    
    v_json_text VARCHAR2(4000);
    v_first_record BOOLEAN := TRUE;
    v_image_exists NUMBER;
    
BEGIN
    DBMS_OUTPUT.PUT_LINE('Начало экспорта товаров в JSON...');
    v_start_date := SYSDATE;
    DBMS_OUTPUT.PUT_LINE('Время начала: ' || TO_CHAR(v_start_date, 'YYYY-MM-DD HH24:MI:SS'));
    
    BEGIN
        v_file := UTL_FILE.FOPEN('JSON_DATA_DIR', p_file_name, 'W', 32767);
        DBMS_OUTPUT.PUT_LINE('Файл открыт: ' || p_file_name);
    EXCEPTION
        WHEN OTHERS THEN
            DBMS_OUTPUT.PUT_LINE('Ошибка открытия файла: ' || SQLERRM);
            RETURN;
    END;
    
    UTL_FILE.PUT_LINE(v_file, '[');
    
    OPEN c_products;
    
    LOOP
        FETCH c_products BULK COLLECT INTO v_products LIMIT v_batch_size;
        
        EXIT WHEN v_products.COUNT = 0;
        
        FOR i IN 1..v_products.COUNT LOOP
            v_total_count := v_total_count + 1;
            
            -- Проверяем наличие изображения
            BEGIN
                SELECT CASE WHEN PRODUCT_IMAGE IS NULL THEN 0 ELSE 1 END
                INTO v_image_exists
                FROM HEAD_ADMIN.PRODUCT
                WHERE ID = v_products(i).ID;
            EXCEPTION
                WHEN OTHERS THEN
                    v_image_exists := 0;
            END;
            
            -- Создаем ВАЛИДНЫЙ JSON с точкой в числах
            v_json_text := 
                '{"id":' || v_products(i).ID ||
                ',"product_name":"' || REPLACE(v_products(i).PRODUCT_NAME, '"', '\"') || '"' ||
                ',"base_price":' || v_products(i).BASE_PRICE_STR ||  -- Используем строку с точкой
                ',"description":"' || REPLACE(NVL(v_products(i).DESCRIPTION, ''), '"', '\"') || '"' ||
                ',"has_image":' || CASE WHEN v_image_exists = 1 THEN 'true' ELSE 'false' END ||
                ',"is_active":' || v_products(i).IS_ACTIVE ||
                ',"created_at":"' || TO_CHAR(SYSDATE, 'YYYY-MM-DD') || '"}';
            
            IF NOT v_first_record THEN
                UTL_FILE.PUT_LINE(v_file, ',');
            ELSE
                v_first_record := FALSE;
            END IF;
            
            UTL_FILE.PUT_LINE(v_file, v_json_text);
        END LOOP;
        
        -- Логирование прогресса
        IF MOD(v_total_count, 10000) = 0 THEN
            DBMS_OUTPUT.PUT_LINE('Экспортировано ' || v_total_count || ' записей...');
            UTL_FILE.FFLUSH(v_file);
        END IF;
        
        v_products.DELETE;
        
    END LOOP;
    
    CLOSE c_products;
    
    UTL_FILE.PUT_LINE(v_file, ']');
    UTL_FILE.FCLOSE(v_file);
    
    v_end_date := SYSDATE;
    
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('ЭКСПОРТ ЗАВЕРШЕН');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Всего записей: ' || v_total_count);
    DBMS_OUTPUT.PUT_LINE('Время начала: ' || TO_CHAR(v_start_date, 'HH24:MI:SS'));
    DBMS_OUTPUT.PUT_LINE('Время окончания: ' || TO_CHAR(v_end_date, 'HH24:MI:SS'));    
    DBMS_OUTPUT.PUT_LINE('Файл: ' || p_file_name);
    DBMS_OUTPUT.PUT_LINE('Размер пакета: ' || v_batch_size);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('ОШИБКА ЭКСПОРТА:');
        DBMS_OUTPUT.PUT_LINE('Ошибка: ' || SQLERRM);
        DBMS_OUTPUT.PUT_LINE('Код ошибки: ' || SQLCODE);
        DBMS_OUTPUT.PUT_LINE('Обработано записей: ' || v_total_count);
        
        BEGIN
            IF c_products%ISOPEN THEN
                CLOSE c_products;
            END IF;
            
            IF UTL_FILE.IS_OPEN(v_file) THEN
                UTL_FILE.FCLOSE(v_file);
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                DBMS_OUTPUT.PUT_LINE('Ошибка при закрытии ресурсов: ' || SQLERRM);
        END;
END EXPORT_PRODUCTS_TO_JSON;
/





-- 2. Процедура импорта товаров из JSON
CREATE OR REPLACE PROCEDURE HEAD_ADMIN.IMPORT_PRODUCTS_FROM_JSON(
    p_file_name VARCHAR2
) IS
    v_total_in_json NUMBER := 0;
    v_updated NUMBER := 0;
    v_inserted NUMBER := 0;
    v_errors NUMBER := 0;
    v_start TIMESTAMP;
    v_end TIMESTAMP;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Импорт товаров из JSON...');
    DBMS_OUTPUT.PUT_LINE('Файл: ' || p_file_name);
    v_start := SYSTIMESTAMP;
    
    -- Просто обновляем существующие записи
    FOR rec IN (
        SELECT 
            jt.id,
            jt.product_name,
            jt.base_price,
            jt.description,
            jt.is_active
        FROM JSON_TABLE(
            BFILENAME('JSON_DATA_DIR', p_file_name),
            '$[*]' 
            COLUMNS (
                id NUMBER PATH '$.id',
                product_name NVARCHAR2(255) PATH '$.product_name',
                base_price NUMBER(10,2) PATH '$.base_price',
                description VARCHAR2(1000) PATH '$.description',
                is_active NUMBER(1) PATH '$.is_active'
            )
        ) jt
        WHERE jt.id IS NOT NULL
    ) 
    LOOP
        v_total_in_json := v_total_in_json + 1;
        
        BEGIN
            -- Проверяем существует ли запись
            DECLARE
                v_exists NUMBER;
            BEGIN
                SELECT COUNT(*) INTO v_exists
                FROM HEAD_ADMIN.PRODUCT
                WHERE ID = rec.id;
                
                IF v_exists > 0 THEN
                    -- Обновляем существующую запись
                    UPDATE HEAD_ADMIN.PRODUCT SET
                        PRODUCT_NAME = rec.product_name,
                        BASE_PRICE = rec.base_price,
                        DESCRIPTION = rec.description,
                        IS_ACTIVE = COALESCE(rec.is_active, 1)
                    WHERE ID = rec.id;
                    
                    v_updated := v_updated + 1;
                ELSE
                    -- Вставляем новую запись БЕЗ указания ID
                    INSERT INTO HEAD_ADMIN.PRODUCT (
                        PRODUCT_NAME,
                        BASE_PRICE,
                        DESCRIPTION,
                        IS_ACTIVE
                    ) VALUES (
                        rec.product_name,
                        rec.base_price,
                        rec.description,
                        COALESCE(rec.is_active, 1)
                    );
                    
                    v_inserted := v_inserted + 1;
                END IF;
            END;
            
            -- Периодический коммит и логирование
            IF MOD(v_total_in_json, 10000) = 0 THEN
                COMMIT;
                v_end := SYSTIMESTAMP;
                DBMS_OUTPUT.PUT_LINE('Обработано ' || v_total_in_json || 
                                   ' записей');
            END IF;
            
        EXCEPTION
            WHEN OTHERS THEN
                v_errors := v_errors + 1;
                -- Минимальный вывод ошибок
                IF v_errors <= 10 THEN
                    DBMS_OUTPUT.PUT_LINE('Ошибка ID ' || rec.id || ': ' || SQLERRM);
                END IF;
                CONTINUE;
        END;
    END LOOP;
    
    COMMIT;
    v_end := SYSTIMESTAMP;
    
    -- Итоговая статистика
    DBMS_OUTPUT.PUT_LINE(CHR(10) || '========================================');
    DBMS_OUTPUT.PUT_LINE('ИМПОРТ ЗАВЕРШЕН');
    DBMS_OUTPUT.PUT_LINE('========================================');
    DBMS_OUTPUT.PUT_LINE('Всего записей в JSON: ' || v_total_in_json);
    DBMS_OUTPUT.PUT_LINE('Обновлено записей:   ' || v_updated);
    DBMS_OUTPUT.PUT_LINE('Добавлено новых:     ' || v_inserted);
    DBMS_OUTPUT.PUT_LINE('Ошибок:              ' || v_errors);
    DBMS_OUTPUT.PUT_LINE('Время выполнения:    ' || 
                        ROUND(EXTRACT(SECOND FROM (v_end - v_start)) + 
                              EXTRACT(MINUTE FROM (v_end - v_start)) * 60, 2) || ' сек');
    
    -- Проверяем итоговое количество
    DECLARE
        v_total_after NUMBER;
    BEGIN
        SELECT COUNT(*) INTO v_total_after FROM HEAD_ADMIN.PRODUCT;
        DBMS_OUTPUT.PUT_LINE('Всего записей в таблице: ' || v_total_after);
    EXCEPTION
        WHEN OTHERS THEN NULL;
    END;
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Критическая ошибка импорта: ' || SQLERRM);
        ROLLBACK;
END IMPORT_PRODUCTS_FROM_JSON;
/




---- 3. Процедура экспорта заказов в JSON
--CREATE OR REPLACE PROCEDURE HEAD_ADMIN.EXPORT_ORDERS_TO_JSON(
--    p_file_name VARCHAR2,
--    p_start_date DATE DEFAULT NULL,
--    p_end_date DATE DEFAULT NULL
--) IS
--    v_json_data CLOB;
--    v_file      UTL_FILE.FILE_TYPE;
--    v_first_row BOOLEAN := TRUE;
--BEGIN
--    v_file := UTL_FILE.FOPEN('JSON_DATA_DIR', p_file_name, 'W');
--    
--    UTL_FILE.PUT_LINE(v_file, '[');
--    
--    FOR rec IN (
--        SELECT JSON_OBJECT(
--            key 'order_id' VALUE UO.ID,
--            key 'order_number' VALUE UO.ORDER_NUMBER,
--            key 'customer_name' VALUE PD_USER.FULL_NAME,
--            key 'customer_phone' VALUE PD_USER.PHONE_NUMBER,
--            key 'delivery_address' VALUE UO.DELIVERY_ADDRESS,
--            key 'status' VALUE UO.STATUS,
--            key 'total_amount' VALUE UO.TOTAL_AMOUNT,
--            key 'order_date' VALUE TO_CHAR(UO.ORDER_DATE, 'YYYY-MM-DD HH24:MI:SS'),
--            key 'shop_name' VALUE FS.SHOP_NAME,
--            key 'courier_name' VALUE PD_COURIER.FULL_NAME
--        ) AS json_data
--        FROM HEAD_ADMIN.USER_ORDER UO
--        JOIN HEAD_ADMIN.APP_USER AU ON UO.USER_ID = AU.ID
--        JOIN HEAD_ADMIN.PERSONAL_DATA PD_USER ON AU.PERSONAL_DATA = PD_USER.ID
--        JOIN HEAD_ADMIN.FLOWER_SHOP FS ON UO.FLOWER_SHOP_ID = FS.ID
--        LEFT JOIN HEAD_ADMIN.COURIER C ON UO.COURIER_ID = C.ID
--        LEFT JOIN HEAD_ADMIN.PERSONAL_DATA PD_COURIER ON C.PERSONAL_DATA_ID = PD_COURIER.ID
--        WHERE (p_start_date IS NULL OR UO.ORDER_DATE >= p_start_date)
--          AND (p_end_date IS NULL OR UO.ORDER_DATE <= p_end_date)
--        ORDER BY UO.ORDER_DATE DESC
--    )
--    LOOP
--        v_json_data := rec.json_data;
--        
--        IF NOT v_first_row THEN
--            UTL_FILE.PUT_LINE(v_file, ',');
--        ELSE
--            v_first_row := FALSE;
--        END IF;
--        
--        UTL_FILE.PUT_LINE(v_file, v_json_data);
--    END LOOP;
--    
--    UTL_FILE.PUT_LINE(v_file, ']');
--    UTL_FILE.FCLOSE(v_file);
--    
--    DBMS_OUTPUT.PUT_LINE('Экспорт заказов завершен. Файл: ' || p_file_name);
--    
--EXCEPTION
--    WHEN OTHERS THEN
--        BEGIN
--            IF UTL_FILE.IS_OPEN(v_file) THEN
--                UTL_FILE.FCLOSE(v_file);
--            END IF;
--        EXCEPTION
--            WHEN OTHERS THEN NULL;
--        END;
--        RAISE_APPLICATION_ERROR(-20001, 'Ошибка экспорта заказов: ' || SQLERRM);
--END EXPORT_ORDERS_TO_JSON;
--/
--
---- 4. Процедура импорта заказов из JSON
--CREATE OR REPLACE PROCEDURE HEAD_ADMIN.IMPORT_ORDERS_FROM_JSON(
--    p_file_name VARCHAR2
--) IS
--    v_count INT := 0;
--BEGIN
--    DBMS_OUTPUT.PUT_LINE('Импорт заказов из JSON в этой версии не реализован');
--    DBMS_OUTPUT.PUT_LINE('Импорт заказов требует сложной логики валидации');
--    DBMS_OUTPUT.PUT_LINE('и проверки внешних ключей');
--EXCEPTION
--    WHEN OTHERS THEN
--        RAISE_APPLICATION_ERROR(-20001, 'Импорт заказов не поддерживается: ' || SQLERRM);
--END IMPORT_ORDERS_FROM_JSON;
--/

-- Проверка
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== СОЗДАНЫ ПРОЦЕДУРЫ JSON ===');
    DBMS_OUTPUT.PUT_LINE('1. EXPORT_PRODUCTS_TO_JSON - экспорт товаров');
    DBMS_OUTPUT.PUT_LINE('2. IMPORT_PRODUCTS_FROM_JSON - импорт товаров');
    DBMS_OUTPUT.PUT_LINE('3. EXPORT_ORDERS_TO_JSON - экспорт заказов');
    DBMS_OUTPUT.PUT_LINE('4. IMPORT_ORDERS_FROM_JSON - заглушка для импорта заказов');
END;
/