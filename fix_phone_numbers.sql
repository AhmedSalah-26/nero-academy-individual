-- Fix phone numbers in profiles table
-- This script removes spaces and formats phone numbers correctly

UPDATE profiles
SET phone = CASE
    -- If phone is null or empty, keep it as is
    WHEN phone IS NULL OR phone = '' THEN phone
    
    -- Remove all non-digit characters except the leading +
    ELSE 
        '+' || REGEXP_REPLACE(
            REGEXP_REPLACE(phone, '^\+', ''), -- Remove leading +
            '[^0-9]', '', 'g'                  -- Remove all non-digits
        )
END
WHERE phone IS NOT NULL 
  AND phone != ''
  AND phone ~ '[^0-9+]'; -- Only update if contains non-digit chars (except +)

-- Verify the changes
-- SELECT id, name, phone FROM profiles WHERE phone IS NOT NULL ORDER BY updated_at DESC LIMIT 20;
