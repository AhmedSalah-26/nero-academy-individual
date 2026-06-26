class PhoneUtils {
  /// Normalizes a phone number for WhatsApp usage.
  /// Handles common Egyptian formats and ensures it starts with the correct country code.
  static String? normalizeWhatsappNumber(String? value) {
    if (value == null || value.isEmpty) return null;
    
    // 1. Remove all non-digit characters (including +, spaces, dashes)
    String digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;

    // 2. Fix common entry mistakes
    // If it starts with 00, strip the 00 (e.g., 002010... -> 2010...)
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    
    // If they typed +20 and also kept the leading 0 (e.g., 20010...)
    if (digits.startsWith('2001') && digits.length >= 12) {
      digits = '20${digits.substring(3)}'; 
    }

    // 3. Normalize Egyptian numbers
    if (digits.startsWith('01') && digits.length == 11) {
      // e.g. 01012345678 -> 201012345678
      digits = '20${digits.substring(1)}';
    } else if (digits.startsWith('1') && digits.length == 10) {
      // e.g. 1012345678 -> 201012345678
      digits = '20$digits';
    }
    
    return digits;
  }
}
