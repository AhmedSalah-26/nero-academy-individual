import DOMPurify from 'dompurify';

const DEFAULT_CONFIG = {
  ALLOWED_TAGS: [
    'h1', 'h2', 'h3', 'h4', 'h5', 'h6',
    'p', 'br', 'hr',
    'ul', 'ol', 'li',
    'strong', 'em', 'b', 'i', 'u', 's',
    'a', 'img',
    'blockquote', 'pre', 'code',
    'table', 'thead', 'tbody', 'tr', 'th', 'td',
    'span', 'div',
    'sub', 'sup',
  ],
  ALLOWED_ATTR: ['href', 'target', 'rel', 'src', 'alt', 'class', 'style', 'id'],
};

export function sanitizeHtml(dirty: string): string {
  return DOMPurify.sanitize(dirty, DEFAULT_CONFIG as any) as unknown as string;
}
