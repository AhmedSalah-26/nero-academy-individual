'use client';

import styles from './PhoneInputField.module.css';

interface PhoneInputFieldProps {
  label?: string;
  value?: string;
  onChange?: (value: string) => void;
  countryCode?: string;
  onCountryCodeChange?: (code: string) => void;
  error?: string;
  required?: boolean;
  placeholder?: string;
  className?: string;
}

const COUNTRY_CODES = [
  { code: '+20', label: 'EG', flag: '🇪🇬' },
  { code: '+966', label: 'SA', flag: '🇸🇦' },
  { code: '+971', label: 'AE', flag: '🇦🇪' },
  { code: '+974', label: 'QA', flag: '🇶🇦' },
  { code: '+965', label: 'KW', flag: '🇰🇼' },
  { code: '+1', label: 'US', flag: '🇺🇸' },
  { code: '+44', label: 'UK', flag: '🇬🇧' },
];

export default function PhoneInputField({
  label,
  value = '',
  onChange,
  countryCode = '+20',
  onCountryCodeChange,
  error,
  required = false,
  placeholder = '01XXXXXXXXX',
  className,
}: PhoneInputFieldProps) {
  const selectedCountry = COUNTRY_CODES.find((c) => c.code === countryCode) || COUNTRY_CODES[0];

  return (
    <div className={`${styles.phoneField} ${className || ''}`}>
      {label && (
        <label className={`${styles.label} ${required ? styles.labelRequired : ''}`}>
          {label}
        </label>
      )}
      <div className={`${styles.inputRow} ${error ? styles.inputError : ''}`}>
        <select
          className={styles.countrySelect}
          value={countryCode}
          onChange={(e) => onCountryCodeChange?.(e.target.value)}
          aria-label="Country code"
        >
          {COUNTRY_CODES.map((c) => (
            <option key={c.code} value={c.code}>
              {c.flag} {c.code}
            </option>
          ))}
        </select>
        <input
          className={styles.phoneInput}
          type="tel"
          value={value}
          onChange={(e) => onChange?.(e.target.value)}
          placeholder={placeholder}
          dir="ltr"
        />
      </div>
      {error && <span className={styles.errorText}>{error}</span>}
    </div>
  );
}
