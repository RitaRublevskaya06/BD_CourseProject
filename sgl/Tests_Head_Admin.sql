SET SERVEROUTPUT OFF;
SET SERVEROUTPUT ON;

BEGIN
  HEAD_ADMIN.HEAD_ADMIN_PACKAGE.REGISTER_SHOP_ADMIN(
    P_FULL_NAME => 'xxxxx',
    P_EMAIL => 'xxxxxxxx@flowers.by',
    P_PHONE_NUMBER => '+37529xxxxxxxx',
    P_DATE_OF_BIRTH => 'xx-xx-xxxx',
    P_PASSWORD => 'xxxxxx' 
  );
END;
/

BEGIN
  HEAD_ADMIN.HEAD_ADMIN_PACKAGE.ADD_FLOWER_SHOP(
    P_SHOP_NAME => 'xxxx',
    P_ADDRESS => 'xxxx',
    P_LOCATION => SDO_GEOMETRY(2001, 4326, SDO_POINT_TYPE(27.496, 53.895, NULL), NULL, NULL),
    P_COVERAGE_AREA => SDO_GEOMETRY(2003, 4326, NULL,
                                     SDO_ELEM_INFO_ARRAY(1, 1003, 1),
                                     SDO_ORDINATE_ARRAY(
                                                        27.486, 53.885,  -- юго-запад: -0.01 по долготе, -0.01 по широте
                                                        27.506, 53.885,  -- юго-восток: +0.01 по долготе, -0.01 по широте  
                                                        27.506, 53.905,  -- северо-восток: +0.01 по долготе, +0.01 по широте
                                                        27.486, 53.905,  -- северо-запад: -0.01 по долготе, +0.01 по широте
                                                        27.486, 53.885   -- замыкается полигон
                                                        )),
    P_SHOP_ADMIN_ID => xx,
    P_OPEN_TIME => TO_TIMESTAMP('00:00:00', 'HH24:MI:SS'),
    P_CLOSE_TIME => TO_TIMESTAMP('00:00:00', 'HH24:MI:SS'),
    P_DELIVERY_START_TIME => TO_TIMESTAMP('00:00:00', 'HH24:MI:SS'),
    P_DELIVERY_END_TIME => TO_TIMESTAMP('00:00:00', 'HH24:MI:SS'),
    P_PHONE => '+37529xxxxxxxx',
    P_EMAIL => 'xxxx@flowers.by'
  );
END;
/

BEGIN
  HEAD_ADMIN.HEAD_ADMIN_PACKAGE.UPDATE_FLOWER_SHOP(
    P_ID => xx,
    P_ADDRESS => 'г. Минск, ул. xxxx, xx'
  );
END;
/

BEGIN
  HEAD_ADMIN.HEAD_ADMIN_PACKAGE.DELETE_FLOWER_SHOP(P_ID => xx);
END;
/

BEGIN
  HEAD_ADMIN.HEAD_ADMIN_PACKAGE.INSERT_PRODUCT(
    P_PRODUCT_NAME => 'xxxx',
    P_BASE_PRICE => xxxx,
    P_DESCRIPTION => 'xxxx',
    P_PRODUCT_IMAGE => NULL
  );
END;
/

BEGIN
  HEAD_ADMIN.HEAD_ADMIN_PACKAGE.UPDATE_PRODUCT(
    P_ID => xxx,
    P_BASE_PRICE => xxx
  );
END;
/

BEGIN
  HEAD_ADMIN.HEAD_ADMIN_PACKAGE.DELETE_PRODUCT(P_ID => xxx);
END;
/

BEGIN
    HEAD_ADMIN.HEAD_ADMIN_PACKAGE.SHOW_FLOWER_SHOPS(1);
END;
/

BEGIN
    HEAD_ADMIN.HEAD_ADMIN_PACKAGE.SHOW_FLOWER_SHOPS(2);
END;
/

BEGIN
    HEAD_ADMIN.HEAD_ADMIN_PACKAGE.SHOW_PRODUCTS(1);
END;
/

BEGIN
    HEAD_ADMIN.HEAD_ADMIN_PACKAGE.SHOW_SHOP_ADMINS;
END;
/

select * from HEAD_ADMIN.PRODUCT_ITEM_INFO;

select * from HEAD_ADMIN.size_category;

select * from HEAD_ADMIN.CART_ITEM;

select * from HEAD_ADMIN.ORDER_ITEM;

select * from HEAD_ADMIN.USER_ROLE;

select * from HEAD_ADMIN.CART_ITEM;

select * from HEAD_ADMIN.FlOWER_SHOP;

select * from HEAD_ADMIN.PRODUCT;

select * from HEAD_ADMIN.APP_USER;