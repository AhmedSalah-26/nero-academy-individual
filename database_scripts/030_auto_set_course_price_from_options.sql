-- Auto-resolve course price to the maximum option price if price is 0 or null
CREATE OR REPLACE FUNCTION handle_course_pricing_fallback()
RETURNS TRIGGER AS $$
DECLARE
  v_max_option_price DECIMAL(10,2) := 0;
BEGIN
  -- If pricing_options is not null and is a valid json array with elements
  IF NEW.pricing_options IS NOT NULL AND jsonb_typeof(NEW.pricing_options) = 'array' AND jsonb_array_length(NEW.pricing_options) > 0 THEN
    -- Extract the maximum price from pricing_options
    SELECT COALESCE(MAX((opt->>'price')::decimal), 0)
    INTO v_max_option_price
    FROM jsonb_array_elements(NEW.pricing_options) AS opt;
    
    -- If the current price is 0 or null and we have a valid max price from options, set it automatically
    IF (NEW.price IS NULL OR NEW.price = 0) AND v_max_option_price > 0 THEN
      NEW.price := v_max_option_price;
    END IF;
  END IF;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_handle_course_pricing_fallback ON courses;

CREATE TRIGGER trg_handle_course_pricing_fallback
BEFORE INSERT OR UPDATE ON courses
FOR EACH ROW
EXECUTE FUNCTION handle_course_pricing_fallback();
