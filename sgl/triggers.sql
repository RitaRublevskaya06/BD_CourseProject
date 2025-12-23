-- 1. Проверка цены товара
CREATE OR REPLACE TRIGGER HEAD_ADMIN.CHECK_PRODUCT_PRICE
    BEFORE INSERT OR UPDATE ON HEAD_ADMIN.PRODUCT
    FOR EACH ROW
DECLARE
    v_warning_msg VARCHAR2(500);
BEGIN
    IF :NEW.BASE_PRICE <= 0 THEN
        v_warning_msg := 'Предупреждение: Цена товара должна быть положительной. ';
        
        IF :NEW.ID IS NOT NULL THEN
            v_warning_msg := v_warning_msg || 'ID=' || :NEW.ID;
        ELSE
            v_warning_msg := v_warning_msg || 'Новый товар';
        END IF;
        
        v_warning_msg := v_warning_msg || '. Установлено значение по умолчанию 1';
        
        :NEW.BASE_PRICE := 1;
        DBMS_OUTPUT.PUT_LINE(v_warning_msg);
    END IF;
END;
/

-- 2. Проверка значений размеров
CREATE OR REPLACE TRIGGER HEAD_ADMIN.CHECK_SIZE_CATEGORY_VALUES
    BEFORE INSERT OR UPDATE ON HEAD_ADMIN.SIZE_CATEGORY
    FOR EACH ROW
DECLARE
    v_has_error BOOLEAN := FALSE;
BEGIN
    IF :NEW.ITEM_SIZE <= 0 THEN
        :NEW.ITEM_SIZE := ABS(:NEW.ITEM_SIZE);
        
        IF :NEW.ID IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('Предупреждение: ITEM_SIZE должен быть положительным числом. ID=' || :NEW.ID);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Предупреждение: ITEM_SIZE должен быть положительным числом. Новый размер');
        END IF;
        
        v_has_error := TRUE;
    END IF;
    
    IF :NEW.MARKUP <= 0 THEN
        :NEW.MARKUP := ABS(:NEW.MARKUP);
        
        IF :NEW.ID IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('Предупреждение: MARKUP должен быть положительным числом. ID=' || :NEW.ID);
        ELSE
            DBMS_OUTPUT.PUT_LINE('Предупреждение: MARKUP должен быть положительным числом. Новый размер');
        END IF;
        
        v_has_error := TRUE;
    END IF;
END;
/

-- 3. Автоматическое обновление доступности курьера 
CREATE OR REPLACE TRIGGER HEAD_ADMIN.TRG_UPDATE_COURIER_AVAILABILITY
    BEFORE UPDATE ON HEAD_ADMIN.COURIER
    FOR EACH ROW
BEGIN
    IF :OLD.IS_ACTIVE = 1 AND :NEW.IS_ACTIVE = 0 THEN
        :NEW.IS_AVAILABLE := 0;
    END IF;
END;
/

-- 4. Проверка зарплаты курьера
CREATE OR REPLACE TRIGGER HEAD_ADMIN.TRG_CHECK_SALARY
    BEFORE INSERT OR UPDATE ON HEAD_ADMIN.COURIER
    FOR EACH ROW
BEGIN
    IF :NEW.SALARY <= 0 THEN
        :NEW.SALARY := 1;
        
        IF :NEW.ID IS NOT NULL THEN
            DBMS_OUTPUT.PUT_LINE('Предупреждение: Зарплата курьера ID=' || :NEW.ID || 
                                ' должна быть больше 0. Установлено минимальное значение');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Предупреждение: Зарплата нового курьера должна быть больше 0. Установлено минимальное значение');
        END IF;
    END IF;
END;
/

-- 5. Автозаполнение ORDER_DATE при создании заказа 
CREATE OR REPLACE TRIGGER HEAD_ADMIN.TRG_SET_ORDER_DATE
    BEFORE INSERT ON HEAD_ADMIN.USER_ORDER
    FOR EACH ROW
BEGIN
    IF :NEW.ORDER_DATE IS NULL THEN
        :NEW.ORDER_DATE := SYSTIMESTAMP;
    END IF;
END;
/

-- Проверка
BEGIN
    DBMS_OUTPUT.PUT_LINE('=== СОЗДАНЫ ТРИГГЕРЫ ===');
    DBMS_OUTPUT.PUT_LINE('1. CHECK_PRODUCT_PRICE');
    DBMS_OUTPUT.PUT_LINE('2. CHECK_SIZE_CATEGORY_VALUES');
    DBMS_OUTPUT.PUT_LINE('3. TRG_UPDATE_COURIER_AVAILABILITY');
    DBMS_OUTPUT.PUT_LINE('4. TRG_CHECK_SALARY');
    DBMS_OUTPUT.PUT_LINE('5. TRG_SET_ORDER_DATE');
END;
/