-- name: CreateAwardLoyaltyPointsTrigger
CREATE OR REPLACE FUNCTION award_loyalty_points_on_order_completion()
RETURNS TRIGGER AS
$$
DECLARE
    points_to_add INT;
BEGIN
    IF NEW.total_amount IS NOT NULL AND NEW.total_amount > 0 AND (OLD.total_amount IS NULL OR OLD.total_amount != NEW.total_amount) THEN
        points_to_add := FLOOR(NEW.total_amount / 10.0);

        IF points_to_add > 0 THEN
            UPDATE Customers
            SET loyalty_points = loyalty_points + points_to_add,
                loyalty_program = TRUE
            WHERE customer_id = NEW.customer_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$
LANGUAGE plpgsql;

-- name: CreateAwardLoyaltyPointsTriggerDefinition
CREATE TRIGGER trg_award_loyalty_points_on_order_completion
AFTER UPDATE OF total_amount ON Orders
FOR EACH ROW
EXECUTE FUNCTION award_loyalty_points_on_order_completion();

-- name: DropAwardLoyaltyPointsTriggerDefinition
DROP TRIGGER IF EXISTS trg_award_loyalty_points_on_order_completion ON Orders;

-- name: DropAwardLoyaltyPointsTriggerFunction
DROP FUNCTION IF EXISTS award_loyalty_points_on_order_completion();
