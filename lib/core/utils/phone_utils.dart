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
    // IMPORTANT: Must start with 01 (not just 1) to be a valid Egyptian mobile
    if (digits.startsWith('01') && digits.length == 11) {
      // e.g. 01012345678 -> 201012345678
      digits = '20${digits.substring(1)}';
    } else if (digits.startsWith('1') && digits.length == 10 && digits[1] == '0') {
      // e.g. 1012345678 -> 201012345678 (only if second digit is 0)
      digits = '20$digits';
    } else if (digits.startsWith('20') && digits.length == 13 && digits[2] == '0' && digits[3] == '1') {
      // Has extra 0: 20010... -> 2010...
      digits = '20${digits.substring(3)}';
    } else if (digits.startsWith('20') && digits.length == 12) {
      // Already in correct format: 201012345678
      return digits;
    }
    
    // Validate final format: must be 12 digits starting with 20
    if (!digits.startsWith('20') || digits.length != 12) {
      return null; // Invalid number
    }
    
    // Validate Egyptian mobile prefix (must be 010, 011, 012, 015)
    final prefix = digits.substring(2, 5);
    if (!['010', '011', '012', '015'].contains(prefix)) {
      return null; // Invalid Egyptian mobile prefix
    }
    
    return digits;
  }
}
