import type { Language } from './translations';

type ValidationResult = string | null;

interface ValidatorOptions {
  lang?: Language;
  minLength?: number;
  maxLength?: number;
  message?: string;
}

const messages = {
  ar: {
    required: 'هذا الحقل مطلوب',
    email: 'البريد الإلكتروني غير صالح',
    passwordMin: 'كلمة المرور يجب أن تكون {min} أحرف على الأقل',
    passwordMatch: 'كلمات المرور غير متطابقة',
    phone: 'رقم الهاتف غير صالح',
    name: 'الاسم مطلوب',
    emailTaken: 'هذا البريد الإلكتروني مسجل بالفعل',
    titleMin: 'العنوان يجب أن يكون {min} أحرف على الأقل',
    contentMin: 'المحتوى يجب أن يكون {min} أحرف على الأقل',
  },
  en: {
    required: 'This field is required',
    email: 'Invalid email address',
    passwordMin: 'Password must be at least {min} characters',
    passwordMatch: 'Passwords do not match',
    phone: 'Invalid phone number',
    name: 'Name is required',
    emailTaken: 'This email is already registered',
    titleMin: 'Title must be at least {min} characters',
    contentMin: 'Content must be at least {min} characters',
  },
};

function msg(lang: Language, key: keyof typeof messages.ar, params?: Record<string, string | number>): string {
  let m = messages[lang][key];
  if (params) {
    Object.entries(params).forEach(([k, v]) => {
      m = m.replace(`{${k}}`, String(v));
    });
  }
  return m;
}

export const Validators = {
  required(value: string, opts: ValidatorOptions = {}): ValidationResult {
    const lang = opts.lang || 'ar';
    if (!value || !value.trim()) return msg(lang, 'required');
    return null;
  },

  email(value: string, opts: ValidatorOptions = {}): ValidationResult {
    const lang = opts.lang || 'ar';
    if (!value || !value.trim()) return msg(lang, 'required');
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(value.trim())) return msg(lang, 'email');
    return null;
  },

  password(value: string, opts: ValidatorOptions = {}): ValidationResult {
    const lang = opts.lang || 'ar';
    const min = opts.minLength || 8;
    if (!value) return msg(lang, 'required');
    if (value.length < min) return msg(lang, 'passwordMin', { min });
    return null;
  },

  confirmPassword(password: string,Confirm: string, opts: ValidatorOptions = {}): ValidationResult {
    const lang = opts.lang || 'ar';
    if (password !== Confirm) return msg(lang, 'passwordMatch');
    return null;
  },

  phone(value: string, opts: ValidatorOptions = {}): ValidationResult {
    const lang = opts.lang || 'ar';
    if (!value || !value.trim()) return msg(lang, 'required');
    const phoneRegex = /^[\+]?[0-9]{8,15}$/;
    if (!phoneRegex.test(value.replace(/[\s\-()]/g, ''))) return msg(lang, 'phone');
    return null;
  },

  name(value: string, opts: ValidatorOptions = {}): ValidationResult {
    const lang = opts.lang || 'ar';
    if (!value || !value.trim()) return msg(lang, 'name');
    return null;
  },

  title(value: string, opts: ValidatorOptions = {}): ValidationResult {
    const lang = opts.lang || 'ar';
    const min = opts.minLength || 10;
    if (!value || !value.trim()) return msg(lang, 'required');
    if (value.trim().length < min) return msg(lang, 'titleMin', { min });
    return null;
  },

  content(value: string, opts: ValidatorOptions = {}): ValidationResult {
    const lang = opts.lang || 'ar';
    const min = opts.minLength || 20;
    if (!value || !value.trim()) return msg(lang, 'required');
    if (value.trim().length < min) return msg(lang, 'contentMin', { min });
    return null;
  },
};
