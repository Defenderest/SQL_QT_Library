-- name: GetOrderHeaderById
SELECT order_id, order_date, total_amount, shipping_address, payment_method
FROM "order"
WHERE order_id = :orderId;

-- name: GetOrderItemsByOrderId
SELECT oi.quantity, oi.price_per_unit, b.title
FROM order_item oi
JOIN book b ON oi.book_id = b.book_id
WHERE oi.order_id = :orderId;

-- name: GetOrderStatusesByOrderId
SELECT status, status_date, tracking_number
FROM order_status
WHERE order_id = :orderId
ORDER BY status_date ASC;

-- name: InsertOrderHeader
INSERT INTO "order" (customer_id, order_date, total_amount, shipping_address, payment_method)
VALUES (:customer_id, CURRENT_TIMESTAMP, 0.0, :shipping_address, :payment_method)
RETURNING order_id;

-- name: GetBookPriceAndStockForUpdate
SELECT price, stock_quantity FROM book WHERE book_id = :book_id FOR UPDATE;

-- name: UpdateBookStock
UPDATE book SET stock_quantity = stock_quantity - :quantity WHERE book_id = :book_id AND stock_quantity >= :quantity;

-- name: InsertOrderItem
INSERT INTO order_item (order_id, book_id, quantity, price_per_unit)
VALUES (:order_id, :book_id, :quantity, :price_per_unit);

-- name: UpdateOrderTotalAmount
UPDATE "order" SET total_amount = :total WHERE order_id = :order_id;

-- name: InsertOrderStatus
INSERT INTO order_status (order_id, status, status_date)
VALUES (:order_id, :status, CURRENT_TIMESTAMP);

-- name: GetCustomerOrderHeadersByCustomerId
SELECT order_id, order_date, total_amount, shipping_address, payment_method
FROM "order"
WHERE customer_id = :customerId
ORDER BY order_date DESC;

-- name: GetOrderItemsByCustomerId
SELECT
    oi.order_id,
    oi.quantity,
    oi.price_per_unit,
    b.title
FROM "order" o
JOIN order_item oi ON oi.order_id = o.order_id
JOIN book b ON b.book_id = oi.book_id
WHERE o.customer_id = :customerId
ORDER BY oi.order_id DESC, oi.order_item_id ASC;

-- name: GetOrderStatusesByCustomerId
SELECT
    os.order_id,
    os.status,
    os.status_date,
    os.tracking_number
FROM "order" o
JOIN order_status os ON os.order_id = o.order_id
WHERE o.customer_id = :customerId
ORDER BY os.order_id DESC, os.status_date ASC;

-- name: GetAllOrdersForAdmin
SELECT
    o.order_id,
    o.customer_id,
    o.order_date::text AS order_date,
    o.total_amount,
    o.shipping_address,
    o.payment_method,
    COALESCE(c.first_name || ' ' || c.last_name, 'Unknown customer') AS customer_name,
    COALESCE(
        (
            SELECT os.status
            FROM order_status os
            WHERE os.order_id = o.order_id
            ORDER BY os.status_date DESC
            LIMIT 1
        ),
        ''
    ) AS last_status
FROM "order" o
LEFT JOIN customer c ON c.customer_id = o.customer_id
ORDER BY o.order_date DESC;

-- name: InsertOrderStatusByAdmin
INSERT INTO order_status (order_id, status, status_date, tracking_number)
VALUES (:order_id, :status, CURRENT_TIMESTAMP, NULLIF(:tracking_number, ''));
