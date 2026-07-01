'use client';

import { type ReactNode, type InputHTMLAttributes, type TextareaHTMLAttributes } from 'react';
import styles from './AppTextField.module.css';

interface AppTextFieldProps {
  label?: string;
  placeholder?: string;
  value?: string;
  onChange?: (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>) => void;
  error?: string;
  helperText?: string;
  type?: string;
  prefixIcon?: ReactNode;
  disabled?: boolean;
  required?: boolean;
  multiline?: boolean;
  rows?: number;
  className?: string;
  name?: string;
  id?: string;
}

export default function AppTextField({
  label,
  placeholder,
  value,
  onChange,
  error,
  helperText,
  type = 'text',
  prefixIcon,
  disabled = false,
  required = false,
  multiline = false,
  rows = 3,
  className,
  name,
  id,
}: AppTextFieldProps) {
  const inputClassNames = [
    styles.input,
    error ? styles.inputError : '',
    prefixIcon ? styles.inputHasPrefix : '',
    multiline ? styles.textarea : '',
  ].filter(Boolean).join(' ');

  return (
    <div className={`${styles.textField} ${className || ''}`}>
      {label && (
        <label className={`${styles.label} ${required ? styles.labelRequired : ''}`} htmlFor={id}>
          {label}
        </label>
      )}
      <div className={styles.inputWrapper}>
        {prefixIcon && <span className={styles.prefixIcon}>{prefixIcon}</span>}
        {multiline ? (
          <textarea
            className={inputClassNames}
            placeholder={placeholder}
            value={value}
            onChange={onChange}
            disabled={disabled}
            rows={rows}
            name={name}
            id={id}
          />
        ) : (
          <input
            className={inputClassNames}
            type={type}
            placeholder={placeholder}
            value={value}
            onChange={onChange}
            disabled={disabled}
            name={name}
            id={id}
          />
        )}
      </div>
      {error && <span className={`${styles.helperText} ${styles.errorText}`}>{error}</span>}
      {!error && helperText && <span className={styles.helperText}>{helperText}</span>}
    </div>
  );
}
