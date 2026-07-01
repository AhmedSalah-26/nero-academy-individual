export interface PricingOptionLike {
  price?: number | string | null;
  originalPrice?: number | string | null;
  label?: string;
  label_ar?: string;
  label_en?: string;
}

export interface CoursePricingLike {
  price?: number | string | null;
  discount_price?: number | string | null;
  is_free?: boolean | null;
  is_flash_sale?: boolean | null;
  flash_sale_price?: number | string | null;
  flash_sale_start?: string | null;
  flash_sale_end?: string | null;
  pricing_options?: unknown;
}

function toNumber(value: number | string | null | undefined): number {
  if (value == null || value === '') return 0;
  const parsed = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(parsed) ? parsed : 0;
}

export function parsePricingOptions(options: CoursePricingLike['pricing_options']): PricingOptionLike[] {
  if (!options) return [];
  if (Array.isArray(options)) return options as PricingOptionLike[];
  if (typeof options !== 'string') return [];

  try {
    const parsed = JSON.parse(options);
    return Array.isArray(parsed) ? parsed as PricingOptionLike[] : [];
  } catch {
    return [];
  }
}

export function getBaseCoursePrice(course: CoursePricingLike): number {
  const directPrice = toNumber(course.price);
  const optionPrices = parsePricingOptions(course.pricing_options)
    .map((option) => toNumber(option.price))
    .filter((price) => price > 0);

  if (directPrice > 0) return directPrice;
  return optionPrices.length > 0 ? Math.max(...optionPrices) : 0;
}

export function getEffectiveCoursePrice(course: CoursePricingLike): number {
  if (course.is_free) return 0;

  const basePrice = getBaseCoursePrice(course);
  const now = Date.now();
  const flashStart = course.flash_sale_start ? new Date(course.flash_sale_start).getTime() : null;
  const flashEnd = course.flash_sale_end ? new Date(course.flash_sale_end).getTime() : null;
  const flashActive =
    !!course.is_flash_sale &&
    (!flashStart || now >= flashStart) &&
    (!flashEnd || now <= flashEnd);
  const flashPrice = toNumber(course.flash_sale_price);

  if (flashActive && flashPrice > 0 && flashPrice < basePrice) {
    return flashPrice;
  }

  const discountPrice = toNumber(course.discount_price);
  if (discountPrice > 0 && discountPrice < basePrice) {
    return discountPrice;
  }

  return basePrice;
}

export function hasCourseDiscount(course: CoursePricingLike): boolean {
  if (course.is_free) return false;
  const basePrice = getBaseCoursePrice(course);
  const effectivePrice = getEffectiveCoursePrice(course);
  return basePrice > 0 && effectivePrice > 0 && effectivePrice < basePrice;
}

export function getCourseDiscountPercentage(course: CoursePricingLike): number | null {
  if (!hasCourseDiscount(course)) return null;
  const basePrice = getBaseCoursePrice(course);
  const effectivePrice = getEffectiveCoursePrice(course);
  return Math.round(((basePrice - effectivePrice) / basePrice) * 100);
}
