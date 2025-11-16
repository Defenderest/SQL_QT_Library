CREATE OR REPLACE FUNCTION calculate_average_book_rating(book_id_param INT)
RETURNS NUMERIC AS $$
DECLARE
    avg_rating NUMERIC;
BEGIN
    SELECT COALESCE(AVG(rating), 0.0)
    INTO avg_rating
    FROM comment
    WHERE book_id = book_id_param AND rating > 0;

    RETURN avg_rating;
END;
$$ LANGUAGE plpgsql;
