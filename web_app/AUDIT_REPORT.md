# LMS Platform — Mobile vs Web Parity Audit Report

**Date:** 2026-07-01  
**Auditor:** Kilo Automated Audit  
**Mobile App:** Flutter (source of truth) — 65 screens, 150+ widgets  
**Web App:** Next.js 16 — 30 unique routes, 41 shared components  

---

## Executive Summary

| Metric | Value |
|---|---|
| **Overall Parity Score** | **42%** |
| Critical Issues | 2 |
| High Issues | 15 |
| Medium Issues | 20 |
| Low Issues | 28 |
| Mobile Screens | 65 |
| Web Screens | 30 |
| Screens with Full Parity | ~12 |
| Screens Needing Work | ~53 |
| Design Token Mismatches | 108+ |

### Major Issues
1. **ThemeCubit overrides** — Mobile renders with brown/earth tones (`#8B4513`) at runtime, completely different from both `AppColors` (blue `#2563EB`) and web (blue `#2563EB`). The declared design system and actual runtime are diverged.
2. **Toast position inverted** — Mobile: top-center; Web: bottom-center.
3. **Background color fundamental mismatch** — Mobile: `#EFF6FF` (blue-tinted); Web: `#F7F6F8` (neutral warm grey).
4. **Bottom navigation architecture differs** — Mobile: floating pill (40px radius, blur 20); Web: flat edge-to-edge bar (blur 16).
5. **Text secondary/muted hierarchy inverted** — Mobile secondary is darker than muted; web secondary is lighter than muted.

### Minor Issues
- Border radius scale diverges at `xl`+ (20 vs 24, 24 vs 32)
- Shadow system: single-shadow (mobile) vs double-shadow (web)
- Skeleton shimmer colors: blue-tinted (mobile) vs neutral grey (web)
- Status light colors: opaque tints (mobile) vs alpha overlays (web)
- Font weight 500/600 not bundled on mobile
- Error toast duration: 4s (mobile) vs 3s (web)
- Web has no splash screen
- Web has no haptic feedback
- Web bottom nav has no floating pill shape
- Web header has glassmorphism; mobile AppBar does not
- Web cards use 16px radius; mobile uses 12px

---

## Complete Parity Comparison Table

| Screen | Section | Component | Mobile | Web | Difference | Required Fix | Priority | Notes |
|---|---|---|---|---|---|---|---|---|
| Splash | — | Entire screen | Animated splash with logo, 1.8s delay, redirect | No splash screen | Web has no splash | Add splash/redirect or accept as platform difference | Low | Web loads directly; splash not expected on web |
| Login | Container | Background | `#EFF6FF` blue-tinted | `#F7F6F8` neutral grey | Different background hue | Change web `--background` to `#EFF6FF` | High | |
| Login | Container | Max width | 520px | 480px | Web card is 40px narrower | Change web card max-width to 520px | Medium | |
| Login | Container | Padding | 40px (28px mobile) | 40px (24px mobile) | Different responsive padding | Align responsive padding | Low | |
| Login | Form | Register stages | 4 stages (Name, Email+Phone, Password, Photo) | 3 stages + submit (Name, Email+Phone, Password) | Web missing Stage 4: Profile Photo upload | Add avatar picker stage | High | |
| Login | Form | Role selection | Mobile has role selection card (Student) in register flow | Web hardcodes `role: 'student'` | Web has no role selection UI | Add role selection (even if student-only) | Medium | |
| Login | Form | Email availability check | Real-time Supabase query on stage transition | No email availability check | Web does not check if email is already registered before submit | Add email uniqueness check | Medium | |
| Login | Social | Google button | Custom `_GoogleIconPainter` with canvas-drawn 4-color "G" | Inline SVG 4-path Google logo | Different icon rendering approach | Align Google icon rendering | Low | |
| Login | Social | Apple/Facebook buttons | Defined (disabled) with `showApple: false`, `showFacebook: false` | Not defined at all | Web has no stubs for future providers | Add disabled social button stubs | Low | |
| Login | Social | Social divider text | "أو سجل بواسطة" (Arabic, localized) | "أو عبر حسابات التواصل الاجتماعي" | Different divider text wording | Align translation strings | Medium | |
| Login | Form | Input label font size | 13px (AuthTextField) / 14px (Forgot Password) | 0.85rem = 13.6px | ~0.6px difference | Set to 13px | Low | |
| Login | Form | Phone input | `PhoneInputField` with `country_picker` (7 countries, favorites: EG, SA, AE, KW, QA) | Hardcoded `+20` prefix | Web has no country code selector; only Egyptian numbers | Use `PhoneInputField` component from `ui/` or add country picker | High | |
| Login | Verification | Card design | 80x80 circle + primary@0.1 background, `mark_email_read_outlined` 44px icon | 80x80 circle + `primaryLight` bg, `MarkEmailUnread` MUI icon | Different icon (outlined vs filled variant), different background approach | Match icon + background | Medium | |
| Login | Verification | Resend button | Outlined with loading spinner (20x20, strokeWidth 2, primary color) | Outlined with CSS spinner (20x20, white border) | Different spinner style | Align resend button spinner | Low | |
| Login | Tabs | Tab switcher animation | `AnimatedAlign` 300ms `easeOutBack` (bounce) | CSS transition 300ms `cubic-bezier(0.34, 1.56, 0.64, 1)` | Similar bounce curve; acceptable match | — | Low | Acceptable |
| Forgot Password | Phase 2 | OTP input | `pinput` package with individual pin boxes | Single text input with `letterSpacing: 8px` | Web has no proper OTP pin boxes; uses plain text input | Implement pin box OTP input | High | |
| Forgot Password | Phase 2 | Password field font size | 16px | 0.95rem = 15.2px | ~0.8px smaller | Set to 16px | Low | |
| Reset Password | Success | Done content | Green checkmark circle (86x86), title + subtitle text, explicit Login button | `successAlert` with `CheckCircle` icon + auto-redirect after 2s | Web has no dedicated done screen with 86x86 circle; auto-redirects | Add done screen matching mobile design | Medium | |
| Interests | Grid | Category icons | Category-specific icons mapped from names | Category-specific MUI icons mapped from names | Icon mappings may differ per category | Verify icon mapping parity | Medium | |
| Interests | Actions | Suggest topic | `ResponsiveDialog` with text field + submit button | Mailto link to `support@shahab.tech` | Web uses email instead of in-app dialog | Add suggest topic dialog | Medium | |
| Interests | Search | Search bar | `GlassSearchBar` (frosted glass) | Basic HTML search input | Web missing glassmorphic design | Use `GlassSearchBar` component | Medium | |
| Home | Layout | Hero section | Custom `HomeHeroSection` with user name greeting + search bar | Marketing landing page for logged-out; `HomeScreen` for logged-in | Web has dual-mode; mobile has single home with hero | Ensure logged-in home matches; accept marketing page as web-only | Medium | |
| Home | Sections | Flash sale section | `HomeFlashSaleSection` with countdown | Web `HomeScreen` has flash sale section | Parity exists | — | — | |
| Home | Sections | Parent portal section | `HomeParentPortalSection` card | `ParentPortalCard` component | Both exist; match styling | Verify visual parity | Low | |
| Home | Sections | Banner carousel | `HomeBannerCarousel` with `carousel_slider` | `BannerCarousel` component | Both exist; verify behavior parity | Verify autoplay, indicators, touch behavior | Medium | |
| Course Details | Layout | Layout structure | Single-column scrollable: hero → stats → what-you-learn → curriculum → instructor → reviews → FAQ → sticky bottom bar | Two-column: left (video + content) + right sidebar (pricing CTA) | Different layout paradigm | Accept desktop 2-column as responsive adaptation; add sticky bottom price bar for mobile view | Medium | |
| Course Details | Actions | Bottom price bar | Sticky bottom bar with Enroll/Add to Cart/Start Learning CTA | No sticky bottom bar; CTA in right sidebar | Web missing sticky mobile price bar | Add sticky bottom bar on mobile viewport | High | |
| Course Details | Sections | What You'll Learn | Separate `WhatYouLearnSection` widget | Objectives listed in sidebar area | Web has no dedicated section | Add dedicated "What You'll Learn" section | Medium | |
| Course Details | Sections | FAQ section | `FAQSection` with expandable tiles | No FAQ section | Web missing FAQ | Add FAQ section | Medium | |
| Course Details | Preview | Preview video | Dedicated `CoursePreviewPlayerScreen` (full overlay) | Inline `<iframe>` or `<VideoPlayer>` | Web uses inline embed, not a full-screen player overlay | Use browser fullscreen API for preview video | Low | |
| Course Details | App Bar | Share/Report | Share + Report icons in AppBar | Share + Report links in page | Different placement | Accept as platform adaptation | Low | |
| Course Player | Tabs | Overview tab | "Overview" tab with course description + objectives | "Lectures" tab showing lesson description | Different tab name and content source | Rename to "Overview" and show course description | High | |
| Course Player | Video | Mini-player overlay | Persistent video mini-player overlay when navigating away from learn page | No mini-player overlay | Web missing persistent mini-player | Accept as platform limitation (web doesn't have app-level overlay) | Low | |
| Course Player | Video | Screen recording protection | `FLAG_SECURE` on Android | No screen recording protection | Web cannot prevent recording | Accept as platform limitation | Low | |
| Course Player | Video | App-lifecycle save | Saves progress on app pause/background | No equivalent (relies on periodic 30s save) | Web missing lifecycle-based save | Accept as platform adaptation (30s auto-save is adequate) | Low | |
| Course Player | Video | Playback speed | Speed options within video controls | Speed menu in player | Similar feature; acceptable | — | Low | |
| Course Player | Navigation | Bottom action bar | Bottom action bar with Back/Complete/Next buttons | Lesson navigation bar with Prev/Complete/Next | Functionally equivalent; different layout | Accept as platform adaptation | Low | |
| Course Player | Tabs | More sub-tabs | More → Attachments, Announcements | More → Notes, Bookmarks, Announcements, Attachments | Different sub-tab ordering | Reorder to match mobile | Low | |
| Course Player | Content | Completion dialog | `CourseCompletedDialog` with animation | Completion dialog | Both exist; verify visual match | Verify parity | Low | |
| Search | Filter | Filter UI | Separate `/search/filter` full-screen page | `CourseFilterSheet` bottom sheet modal | Different presentation: full-screen vs bottom sheet | Accept bottom sheet as platform-adapted web pattern | Medium | |
| Search | UX | Recent searches | Mobile stores recent searches | Web stores in `localStorage` | Both persist; acceptable | — | Low | |
| Q&A | Scope | URL structure | `/qa/:courseId` (course-scoped) | `/qa?q=courseId&lessonId=` (query-param filtered) | Different URL patterns | Accept as web routing pattern | Low | |
| Q&A | Ask question | Ask form | Dedicated `/qa/:courseId/ask` route | Inline modal within `/qa` page | Web embeds form in modal; mobile uses separate route | Accept as platform adaptation | Medium | |
| Quiz | Architecture | Screen structure | 3 separate routed screens (info, questions, results) | Single-page 3-phase state machine | Different architecture; same functionality | Accept as platform adaptation | Low | |
| Quiz | Hub | Centralized exam list | No hub; accessed only from course player | `/exams` hub listing all enrolled quizzes | Web has extra page not on mobile | Add mobile exam hub, or remove web `/exams` | Medium | |
| Quiz | Features | Question navigator | Step-by-step question navigation | Question navigator dots + progress bar | Web has more visual navigation aids | Accept web enhancement as ok; add to mobile if desired | Low | |
| Cart | Feature | Feature parity | Full cart with items, coupon, summary, checkout CTA | Full cart with items, coupon, summary, checkout CTA | Functionally equivalent | Verify visual parity | Low | |
| Checkout | Success | Post-payment | `/payment-success` with orderId display | `/checkout/success` with Paymob verification loop + WhatsApp link | Web has more elaborate verification | Accept web verification flow | Low | |
| Profile | Avatar | Avatar fallback | Icon fallback (`person` icon) | Initials fallback | Different fallback approach | Use icons to match mobile | Medium | |
| Profile | Stats | Version display | No version displayed | Shows "Version 2.4.0" | Web shows version, mobile doesn't | Remove version from web or add to mobile | Low | |
| Profile | Menu | Instructor dashboard link | Link to `/instructor` dashboard | Link to `/instructor` (which doesn't exist on web) | Web link points to non-existent page | Remove link or hide if not instructor | High | |
| Settings | Dark mode | Theme toggle | `ThemeCubit` with earth/brown tones | CSS `[data-theme="dark"]` with blue tones | **Completely different dark mode colors** | Fix ThemeCubit to use AppColors or update web to match ThemeCubit | Critical | |
| Settings | Legal | Privacy policy | No privacy policy page | `/privacy` with Arabic privacy policy | Web has extra legal page | Add privacy to mobile | Medium | |
| Settings | Legal | Terms of service | `/terms-of-service` in-app screen | `/terms` with Arabic terms | Both exist; verify content parity | Verify content matches | Low | |
| Help & Support | — | Entire screen | `/help-support` with FAQ, topics grid, search, contact | No help/support page on web | Web missing entirely | Add `/help-support` page | High | |
| Instructor Profile | — | Entire screen | `/instructor/profile/:instructorId` with bio, stats, courses, reviews, social, follow, contact | No instructor profile page | Web missing entirely | Add instructor profile page | High | |
| Report | — | Entire screen | `/report` standalone screen | No dedicated report screen/route | Web missing report flow | Add report page | High | |
| Forums Management | — | Entire screen | `/forums-management` for instructor admin | No forums management on web | Web missing entirely | Add forums management for instructors | High | |
| Notifications | Position | Toast position | Top-center | Bottom-center (fixed bottom: 24px) | **Inverted position** | Move web toasts to top-center | High | |
| Notifications | Style | Toast background | Full colored background (success=green, error=red) | Neutral card bg + 3px accent border | Different visual style | Match mobile's colored background | Medium | |
| Notifications | Duration | Error toast | 4 seconds | 3 seconds | Different auto-close | Set web error toast to 4s | Low | |
| Bottom Nav | Shape | Container | Floating pill, 40px border-radius, proportional padding | Flat edge-to-edge bar, no border-radius | **Fundamentally different shape** | Implement floating pill nav on mobile viewport | High | |
| Bottom Nav | Blur | Backdrop filter | sigma 20 | blur(16px) | Different blur intensity | Change to blur(20px) | Medium | |
| Bottom Nav | Background | Opacity | Light: white@0.52 / Dark: surfaceDark@0.58 | Light: white@0.72 / Dark: dark@0.72 | Different opacities | Match mobile opacity values | Medium | |
| Bottom Nav | Border | Style | Light: primary@0.25 / Dark: white@0.15, width 1.5 | Light: rgba(0,0,0,0.08) / Dark: rgba(148,163,184,0.12), width 1 | Different border color, width | Match mobile border values | Medium | |
| Bottom Nav | Active tab | Style | Pill bg: primary@0.04, border: primary@0.16, primary icon | Solid primary circle bg, white icon | Different active indicator | Match mobile active tab pill style | High | |
| Bottom Nav | Inactive tab | Icon color (dark) | `grey400` = `#9CA3AF` | `textMuted` = `#94A3B8` | Different grey (154 vs 148) | Set to `#9CA3AF` | Low | |
| Bottom Nav | Haptics | Tab tap | `HapticFeedback.selectionClick()` | No haptic feedback | Platform limitation | Accept as web limitation | Low | |
| Header | Shape | Container | No header on main tabs (only custom AppBars on detail screens) | Glassmorphic floating container, 24px radius (desktop) / 16px (mobile) | Mobile has no persistent global header | Accept as platform adaptation (web needs desktop nav) | Medium | |
| Header | Blur | Backdrop filter | N/A | blur(22px) saturate(1.2) | Mobile has no blur header | Accept desktop header as web-only | Low | |
| Shimmer | Colors | Base (light) | `#DCEBFF` (blue-tinted) | `#F3F4F6` (neutral grey) | Different shimmer base color | Change web to `#DCEBFF` | Medium | |
| Shimmer | Colors | Highlight (light) | `#F0F7FF` | `surface-hover` (primary@0.04) | Different shimmer highlight | Change web to `#F0F7FF` | Medium | |
| Shimmer | Colors | Base (dark) | `#15223A` | `#1E293B` (surface-soft dark) | Different dark shimmer base | Change web to `#15223A` | Medium | |
| Shimmer | Colors | Highlight (dark) | `#1F3152` | Not defined | Web missing dark shimmer highlight | Add dark shimmer highlight `#1F3152` | Medium | |
| Cards | Border radius | Default | 12px (AppTheme cardTheme) | 16px (AppCard.module.css) | 4px difference | Change web card radius to 12px | Medium | |
| Cards | Elevation (light) | Default | 0 (AppTheme) / 2 (ThemeCubit runtime) | shadow-md (always present) | Mismatched elevation model | Align card elevation | Medium | |
| Cards | Dark color | Background | `#172033` (cardDark) | `#1E293B` (surfaceCard dark) | Different dark card color | Change web to `#172033` | Medium | |
| Inputs | Label | Font weight | w500 (label) | 600 (semibold) | Mobile uses medium (500); web uses semibold (600) | Change web to 500 | Medium | |
| Inputs | Focused | Border width | 1 (AppTheme) / 2 (ThemeCubit) | 1px solid primary | Depends on which mobile theme is active | Resolve ThemeCubit conflict first | Medium | |
| Buttons | Size | Small height | 36px | 36px | Match | — | — | |
| Buttons | Size | Medium height | 48px | 44px | 4px difference | Change web medium to 48px | Medium | |
| Buttons | Size | Large height | 56px | 52px | 4px difference | Change web large to 56px | Medium | |
| Buttons | Animation | Press scale | 1.0 → 0.95, 100ms | scale(0.97), 200ms transition | Different scale and timing | Match mobile: scale 0.95, 100ms | Low | |
| Buttons | Glow | Primary shadow | primary@0.4 blur 12 + primary@0.2 blur 20 spread 2 | `--shadow-primary: 0 16px 34px rgba(37,99,235,0.18)` | Different glow intensity | Match mobile glow values | Low | |

---

## Design System Differences

### Colors

| Category | Token | Mobile (AppColors) | Web (CSS Var) | Status |
|---|---|---|---|---|
| Background | Light | `#EFF6FF` | `#F7F6F8` | MISMATCH — different hue |
| Background | Dark | `#07111F` | `#0F172A` | MISMATCH — mobile is deeper |
| Surface | Dark (opaque) | `#0F172A` | `rgba(30,41,59,0.86)` | MISMATCH — transparency |
| Card | Dark | `#172033` | `#1E293B` | MISMATCH |
| Primary | Light | `#BFDBFE` | `#DBEAFE` | MISMATCH — 1 step lighter on web |
| Primary | Light (dark mode) | `#BFDBFE` | `#1E3A5F` | CRITICAL MISMATCH — opposite directions |
| Text | Main (light) | `#0F172A` | `#111827` | MISMATCH — close but different |
| Text | Muted (light) | `#4B5563` | `#6B7280` | MISMATCH — mobile darker for contrast |
| Text | Muted (dark) | `#D1D5DB` | `#94A3B8` | MISMATCH — very different |
| Text | Secondary (light) | `#475569` | `#9CA3AF` | CRITICAL — inverted hierarchy |
| Text | Secondary (dark) | `#CBD5E1` | `#64748B` | CRITICAL — inverted hierarchy |
| Border | Light | `#E5E7EB` (solid) | `rgba(0,0,0,0.10)` (alpha) | MISMATCH — approach differs |
| Border | Dark | `#374151` (solid) | `rgba(148,163,184,0.15)` (alpha) | MISMATCH |
| Status | Success light | `#DCFCE7` (solid) | `rgba(34,197,94,0.10)` (alpha) | MISMATCH |
| Status | Error light | `#FEE2E2` (solid) | `rgba(239,68,68,0.10)` (alpha) | MISMATCH |
| Status | Warning light | `#FEF3C7` (solid) | `rgba(245,158,11,0.10)` (alpha) | MISMATCH |
| Status | Info light | `#DBEAFE` (solid) | `rgba(59,130,246,0.10)` (alpha) | MISMATCH |

### Typography

| Aspect | Mobile | Web | Status |
|---|---|---|---|
| Font family | Almarai (bundled: 300, 400, 700, 800) | Almarai (Google Fonts: 300-800) | MATCH in family; web has more weights |
| Body default size | 14px (`bodyMedium`) | 16px (`1rem`) | MISMATCH |
| Label small | 11px | 12px (`0.75rem`) | MISMATCH |
| Line height system | Defined per style (1.2–1.5) | No global tokens; browser defaults | MISMATCH |
| Letter spacing | Defined per style (-0.5 to 0.5) | No global tokens | MISMATCH |
| Display max size | 32px | 48px (`3rem`) | MISMATCH — web goes larger |

### Icons

| Aspect | Mobile | Web | Status |
|---|---|---|---|
| Icon library | Material Icons (Flutter) | MUI Icons (@mui/icons-material) | MATCH in source (both Material) |
| Google G icon | Custom canvas painter | Inline SVG (4 paths) | Different technique |
| Tab icons | `home_outlined` / `home_rounded` pair | `Home` MUI icon | Acceptable match |
| Phone icon | `PhoneInputField` with country flag | Hardcoded `+20` text | MISMATCH |
| Category icons | Custom mapping | MUI icon mapping | Needs verification per category |

### Buttons

| Aspect | Mobile | Web | Status |
|---|---|---|---|
| Variants | primary, secondary, outline, text, success, error | primary, secondary, outline, text, success, error | MATCH |
| Sizes | small 36h, medium 48h, large 56h | small 36h, medium 44h, large 52h | MISMATCH — medium +4, large +4 |
| Press animation | scale 0.95, 100ms | scale 0.97, 200ms | MISMATCH |
| Haptic feedback | Yes (lightImpact) | No | Platform limitation |
| Border radius | 12px | 12px | MATCH |

### Inputs

| Aspect | Mobile | Web | Status |
|---|---|---|---|
| Border radius | 12px | 12px | MATCH |
| Content padding | h(16), v(14/16) | h(16), height: 44px | Acceptable match |
| Focus shadow | primary@0.15, blur 8, offset (0,2) | `0 0 0 3px primary-glow` | Different approach |
| Label weight | w500 | 600 | MISMATCH |
| Error border | `error` color solid | `error` color + `0 0 0 3px error-light` | Web has focus ring on error |

### Cards

| Aspect | Mobile | Web | Status |
|---|---|---|---|
| Border radius | 12px (AppTheme) | 16px | MISMATCH +4px |
| Padding | 16px | 16px | MATCH |
| Press animation | scale 0.98, 100ms | scale 0.98, hover: scale 1.01 | Different interaction model |
| Light border | `#E5E7EB` | `rgba(0,0,0,0.10)` | Different approach |

### Navigation

| Aspect | Mobile | Web | Status |
|---|---|---|---|
| Bottom nav shape | Floating pill (40px radius) | Flat edge-to-edge | CRITICAL MISMATCH |
| Bottom nav blur | sigma 20 | blur(16px) | MISMATCH |
| Bottom nav bg opacity (light) | white@0.52 | white@0.72 | MISMATCH |
| Bottom nav border | primary@0.25, 1.5px | rgba(0,0,0,0.08), 1px | MISMATCH |
| Active tab | Pill bg + border | Solid primary circle | MISMATCH |
| Desktop header | None | Glassmorphic floating container | Web-only — acceptable |
| Tab preservation | IndexedStack (preserves state) | No state preservation | Platform difference |

### Dialogs

| Aspect | Mobile | Web | Status |
|---|---|---|---|
| Border radius | 16px | 16px | MATCH |
| Max width (desktop) | 500px | sm=400, md=560, lg=720 | Different sizing |
| Overlay | black@0.7 | `rgba(0,0,0,0.7)` | MATCH |
| Entry animation | Flutter dialog animation | CSS: overlay 0.2s + dialog 0.3s scale | Acceptable |

### Forms

| Aspect | Mobile | Web | Status |
|---|---|---|---|
| Validation timing | On submit + field-level | On submit + clearing on change | Similar |
| Error display | Red border + helper text | `.inputError` border + `.fieldError` text | Acceptable match |
| Phone validation | Egyptian prefix check (010/011/012/015) | Generic regex `/^[\+]?[0-9]{8,15}$/` | MISMATCH — web less strict |
| Email availability | Real-time Supabase check | No check | MISSING on web |

---

## Missing Features (Mobile → Web)

| # | Feature | Mobile Route | Priority |
|---|---|---|---|
| 1 | Help & Support page | `/help-support` | High |
| 3 | Instructor Public Profile page | `/instructor/profile/:instructorId` | High |
| 4 | Report Screen | `/report` | High |
| 5 | Forums Management (instructor admin) | `/forums-management` | High |
| 6 | Profile Photo upload in registration | (Stage 4 in register flow) | High |
| 7 | Role selection in registration | (Stage in register flow) | Medium |
| 8 | Country code phone selector in registration | `PhoneInputField` | High |
| 9 | OTP pin box input (vs. plain text) | `pinput` package | High |
| 10 | Dedicated "What You'll Learn" section on course details | `WhatYouLearnSection` | Medium |
| 11 | FAQ section on course details | `FAQSection` | Medium |
| 12 | Sticky bottom price bar on course details (mobile viewport) | `BottomPriceBar` | High |
| 13 | Course preview full-screen overlay | `CoursePreviewPlayerScreen` | Medium |
| 14 | "Overview" tab in course player (vs. "Lectures") | (Player tab) | Medium |
| 15 | Suggest Topic dialog (vs. mailto) | `ResponsiveDialog` | Medium |
| 16 | Direct chat per-conversation deep links | `/chat/:conversationId` | Low |
| 17 | Forum group member management | `CourseGroupMembersScreen` | Medium |
| 18 | Apple/Facebook social login stubs | `SocialLoginButtons` (disabled) | Low |
| 19 | Haptic feedback on tab switch | `HapticFeedback.selectionClick()` | Low (platform) |
| 20 | Video mini-player persistent overlay | `VideoMiniPlayerOverlay` | Low (platform) |
| 21 | Email availability check during registration | (Auth remote data source) | Medium |

## Extra Features (Web → Mobile — Not in Source of Truth)

| # | Feature | Web Route | Recommendation |
|---|---|---|---|
| 1 | Marketing Landing Page (logged-out) | `/` | Accept — web needs logged-out experience |
| 2 | Centralized Exams Hub | `/exams` | Add to mobile for parity |
| 3 | Certificates Gallery | `/certificates` | Add to mobile for parity |
| 4 | Parent Portal | `/parent-portal` | Add to mobile for parity |
| 5 | Privacy Policy page | `/privacy` | Add to mobile for parity |
| 6 | Paymob verification loop at checkout success | `/checkout/success` | Accept as web-specific payment flow |
| 7 | Desktop Header with glassmorphism | `Header` component | Accept as web navigation pattern |
| 8 | Page transition animations (GSAP) | `PageTransition` component | Accept as web enhancement |
| 9 | Staggered animation classes | `.stagger-1` to `.stagger-8` | Accept as web enhancement |
| 10 | Version number in profile/settings | Displayed in settings | Add to mobile |

---

## Implementation Roadmap

### Phase 1 — Critical Blockers (Est. 2-3 weeks)
1. Resolve ThemeCubit color conflict — decide whether mobile runtime should be blue (`#2563EB`) or brown (`#8B4513`); align web accordingly
2. Fix toast position (move web to top-center)
3. Fix background color (web `--background` light = `#EFF6FF`)
4. Fix text secondary/muted hierarchy inversion

### Phase 2 — UI Parity (Est. 2-3 weeks)
1. Implement floating pill bottom nav on web mobile viewport
2. Match bottom nav blur, opacity, border, and active tab styling
3. Align border radius scale (xl=20, 2xl=24)
4. Match card radius (12px), dark card color (`#172033`)
5. Align button heights (medium=48, large=56)
6. Align skeleton/shimmer colors (blue-tinted)
7. Match status light colors (opaque vs alpha)
8. Align border approach (solid hex vs alpha)
9. Fix OTP input to use pin boxes
10. Add phone country code selector

### Phase 3 — UX Parity (Est. 2 weeks)
1. Add Help & Support page
2. Add Instructor Profile page
3. Add Report Screen
4. Add Forums Management (instructor)
5. Add "What You'll Learn" section on course details
6. Add FAQ section on course details
7. Add sticky bottom price bar on mobile viewport
8. Fix "Overview" tab naming in course player
9. Add Suggest Topic dialog
10. Add email availability check in registration

### Phase 4 — Component Parity (Est. 1-2 weeks)
1. Add Profile Photo upload stage in registration
2. Add Role Selection in registration
3. Add Apple/Facebook social login stubs
4. Reset Password done screen (86x86 checkmark circle)
5. Match verification card icon (`mark_email_read_outlined`)
6. Match registration stage count and flow
7. Verify all category icon mappings

### Phase 5 — Responsive Refinement (Est. 1 week)
1. Ensure mobile viewport matches mobile app layout
2. Desktop viewport may adapt layout but maintain design language
3. Test all pages at 320px, 375px, 768px, 1024px, 1440px
4. Verify touch targets (48px minimum)
5. Verify safe area handling

### Phase 6 — Final QA (Est. 1 week)
1. Pixel-compare every screen at mobile viewport
2. Verify all colors match exactly
3. Verify all fonts match exactly
4. Verify all spacing matches exactly
5. Verify all animations match timing
6. Verify all API calls match behavior
7. Cross-browser testing (Chrome, Firefox, Safari, Edge)
8. Accessibility testing (keyboard, screen reader)

---

## QA Checklist

### Authentication
- [ ] Login form: email + password fields with correct validation
- [ ] Register: 4-stage wizard (Name → Email+Phone → Password → Photo)
- [ ] Register: country code phone selector with 5+ countries
- [ ] Register: email availability check on stage transition
- [ ] Register: role selection card (student)
- [ ] Google OAuth: works end-to-end
- [ ] Forgot password: OTP pin box input (not plain text)
- [ ] Forgot password: resend code with loading state
- [ ] Reset password: done screen with 86x86 checkmark circle
- [ ] Interests: minimum 3, suggest topic dialog (not mailto)

### Navigation
- [ ] Bottom nav: floating pill shape with 40px radius on mobile viewport
- [ ] Bottom nav: blur(20px), white@0.52 (light) / surfaceDark@0.58 (dark)
- [ ] Bottom nav: active tab = pill bg with primary@0.04 + primary@0.16 border
- [ ] Bottom nav: inactive tab = grey500 (light) / grey400 (dark) icon
- [ ] Desktop header: present on desktop viewport
- [ ] Tab state: preserved when switching tabs

### Colors
- [ ] Background light: `#EFF6FF`
- [ ] Background dark: `#07111F`
- [ ] Card dark: `#172033`
- [ ] Surface dark: `#0F172A` (opaque)
- [ ] Primary light: `#BFDBFE`
- [ ] Text main light: `#0F172A`
- [ ] Text muted light: `#4B5563`
- [ ] Text secondary light: `#475569`
- [ ] Text muted dark: `#D1D5DB`
- [ ] Text secondary dark: `#CBD5E1`
- [ ] Border light: `#E5E7EB` (solid)
- [ ] Border dark: `#374151` (solid)
- [ ] Shimmer base light: `#DCEBFF`
- [ ] Shimmer highlight light: `#F0F7FF`

### Typography
- [ ] Font family: Almarai
- [ ] Body default: 14px
- [ ] Label small: 11px
- [ ] Input label weight: 500 (not 600)
- [ ] Line height values defined per style
- [ ] Letter spacing values defined per style

### Components
- [ ] Card radius: 12px
- [ ] Button heights: small=36, medium=48, large=56
- [ ] Press animation: scale 0.95, 100ms
- [ ] Input focus: primary color border (1px)
- [ ] Toast: top-center position
- [ ] Toast: colored background (not neutral card)
- [ ] Toast error: 4s auto-close

### Course Details
- [ ] "What You'll Learn" section present
- [ ] FAQ section present
- [ ] Sticky bottom price bar on mobile viewport
- [ ] Preview video with fullscreen capability
- [ ] Instructor card with navigation to profile
- [ ] Share + Report actions accessible

### Course Player
- [ ] "Overview" tab (not "Lectures")
- [ ] All sub-tabs: Notes, Bookmarks, Announcements, Attachments
- [ ] Completion dialog with animation
- [ ] Lesson navigation: Prev/Complete/Next
- [ ] Playback speed control
- [ ] 30s auto-save progress

### Instructor Dashboard
- [ ] Profile menu: instructor dashboard link hidden or functional for instructors

### Missing Web Screens
- [ ] `/help-support` — Help & Support page
- [ ] `/instructor/profile/:id` — Instructor public profile
- [ ] `/report` — Report content screen
- [ ] `/forums-management` — Forum admin for instructors

### Missing Mobile Screens
- [ ] `/exams` — Centralized exam hub
- [ ] `/certificates` — Certificate gallery
- [ ] `/parent-portal` — Parent monitoring
- [ ] `/privacy` — Privacy policy

---

## Final Acceptance Criteria

The audit is considered resolved when:
1. All Critical and High issues are fixed
2. Design token parity reaches 95%+ (allowing for documented platform adaptations)
3. All shared screens exist on both platforms
4. Toast position, background color, and bottom nav shape match
5. ThemeCubit conflict is resolved and both platforms render identically
6. All QA checklist items pass
7. Color hex values match exactly (excluding documented alpha-over-rendering differences)
8. Font family, sizes, and weights match
9. Border radius values match per component
10. Button heights match exactly
11. All API-driven states (loading, empty, error, success) behave identically
12. No unauthorized features exist on web that don't exist on mobile (except documented web-only features)
13. Visual regression testing confirms pixel-level match at 375px viewport width

---

## التقييم الشامل (Comprehensive Evaluation)

### 1. تقييم التماثل البصري (Visual Parity Score): 55/100

| العنصر | النسبة | السبب |
|---|---|---|
| الألوان الأساسية (Primary/Status) | 90% | الألوان الرئيسية متطابقة، اختلاف في approach فقط (solid vs alpha) |
| ألوان الخلفية والأسطح | 40% | `#EFF6FF` vs `#F7F6F8`، `#172033` vs `#1E293B`، alpha vs opaque |
| ألوان النصوص | 35% | التسلسل الهرمي معكوس بين secondary/muted، اختلافات كبيرة في dark mode |
| الحدود (Borders) | 45% | solid vs alpha، ألوان مختلفة في الوضع الداكن |
| الشبومر (Shimmer) | 20% | ألوان مختلفة تماماً (أزرق vs رمادي) |
| الظلال (Shadows) | 50% | single vs double shadow، اختلاف في dark mode |
| **المعدل** | **55%** | |

### 2. تقييم التماثل التخصصي (Typography Parity Score): 65/100

| العنصر | النسبة | السبب |
|---|---|---|
| نوع الخط | 100% | كلاهما يستخدم Almarai |
| أوزان الخط المتوفرة | 70% | Web يحمل 500/600، الموبايل لا يملك ملفات TTF لهما |
| أحجام الخطوط | 55% | اختلاف في الحجم الافتراضي (14px vs 16px)، عدم تطابق في المقاسات الكبيرة |
| ارتفاع السطر (Line Height) | 40% | الموبايل يعرف لكل style، الويب يعتمد على browser defaults |
| تباعد الحروف (Letter Spacing) | 40% | نفس المشكلة |
| **المعدل** | **65%** | |

### 3. تقييم التماثل في المكونات (Component Parity Score): 60/100

| المكون | النسبة | السبب |
|---|---|---|
| أزرار (Buttons) | 75% | ارتفاعات مختلفة (medium +4, large +4)، حركة ضغط مختلفة |
| حقول إدخال (Inputs) | 70% | وزن label مختلف (500 vs 600)، focus ring مختلف |
| بطاقات (Cards) | 60% | radius مختلف (12 vs 16)، لون dark مختلف |
| شريط تنقل سفلي (Bottom Nav) | 25% | شكل مختلف تماماً (floating pill vs flat bar)، blur مختلف، opacity مختلف |
| شريط رأسي (Header/AppBar) | 50% | الموبايل بدون header ثابت، الويب بـ glassmorphism |
| Toast/إشعارات | 30% | موقع معكوس (top vs bottom)، لون الخلفية مختلف |
| Shimmer/Skeleton | 40% | ألوان مختلفة، تقنية مختلفة |
| الحوارات (Dialogs) | 85% | متشابهة جداً |
| **المعدل** | **60%** | |

### 4. تقييم التماثل الوظيفي (Functional Parity Score): 70/100

| القسم | النسبة | السبب |
|---|---|---|
| تسجيل الدخول/التسجيل | 70% | نقص مرحلة الصورة، country code selector، email availability check |
| نسيت كلمة المرور | 60% | OTP pin boxes مفقودة في الويب، done screen مختلف |
| تفاصيل الكورس | 65% | نقص "What You'll Learn"، FAQ، sticky bottom bar |
| مشغل الكورس | 80% | متشابه مع اختلاف اسم "Overview" وترتيب sub-tabs |
| البحث والفلترة | 85% | متشابه وظيفياً، اختلاف طريقة العرض |
| سلة التسوق والدفع | 80% | متشابه |
| الملف الشخصي والإعدادات | 75% | اختلاف dark mode ألوان، نقص صفحات |
| المنتديات والشات | 70% | نقص forums management، مختلف URL scheme |
| الكويزات والاختبارات | 85% | متشابه وظيفياً |
| الشهادات | 0% | الموبايل لا يملك صفحة شهادات |
| بوابة ولي الأمر | 0% | الموبايل لا يملك بوابة ولي الأمر |
| مساعدة ودعم | 0% | الويب لا يملك صفحة مساعدة |
| ملف المدرب | 0% | الويب لا يملك صفحة ملف المدرب |
| التبليغ | 0% | الويب لا يملك صفحة تبليغ |
| **المعدل** | **70%** | |

### 5. تقييم التماثل في التنقل (Navigation Parity Score): 50/100

| العنصر | النسبة | السبب |
|---|---|---|
| شريط التنقل السفلي | 25% | floating pill vs flat bar، كل القيم مختلفة |
| التنقل بين التبويبات | 60% | نفس الـ 4 tabs لكن بدون state preservation في الويب |
| الرجوع (Back) | 80% | متشابه وظيفياً |
| الروابط العميقة (Deep Links) | 50% | الموبايل يدعم /chat/:id، الويب لا يملك per-conversation URL |
| حماية المسارات (Auth Guard) | 50% | الموبايل GoRouter redirect، الويب client-side فقط |
| **المعدل** | **50%** | |

### 6. تقييم التماثل في الرسوم المتحركة (Animation Parity Score): 45/100

| العنصر | النسبة | السبب |
|---|---|---|
| انتقال الصفحات | 40% | الموبايل GoRouter platform-adaptive، الويب CSS fadeIn/simple |
| حركات التمرير (Scroll) | 60% | الويب GSAP ScrollTrigger، الموبايل بسيط |
| حركات الأزرار | 50% | scale 0.95 (100ms) vs scale 0.97 (200ms) |
| حركات التوست | 30% | مواقع مختلفة، animations مختلفة |
| Stagger animations | 70% | الويب يملك stagger classes، الموبايل يدعمها يدوياً |
| Reduced motion | 20% | الموبايل لا يدعم prefers-reduced-motion |
| **المعدل** | **45%** | |

### 7. تقييم التماثل في التجاوب (Responsive Parity Score): 75/100

| العنصر | النسبة | السبب |
|---|---|---|
| viewport الموبايل (375px) | 70% | الويب يقترب لكن يختلف في الـ bottom nav والـ padding |
| viewport التابلت (768px) | 75% | متشابه مع اختلافات الـ layout |
| viewport الديسكتوب (1440px) | 80% | الويب يتكيف جيداً، الموبايل لا يعرض الديسكتوب |
| Touch targets | 60% | الويب لا يضمن 48px في كل العناصر |
| **المعدل** | **75%** | |

### 8. تقييم إمكانية الوصول (Accessibility Score): 55/100

| العنصر | النسبة | السبب |
|---|---|---|
| ترتيب التركيز (Focus Order) | 60% | الويب متوسط، الموبايل يعتمد على_semantics |
| Keyboard Navigation | 50% | الويب يدعم جزئياً، اختصارات محدودة |
| ARIA Labels | 60% | بعض العناصر عليها aria-label، ليس الكل |
| Contrast Ratios | 70% | الموبايل حسّن contrast (textMuted 4B5563)، الويب لا يزال 6B7280 |
| Screen Reader | 50% | الموبايل Semantics جزئي، الويب ARIA جزئي |
| **المعدل** | **55%** | |

### 9. تقييم الأمان والحالة (Security & State Score): 65/100

| العنصر | النسبة | السبب |
|---|---|---|
| حماية المسارات (Route Protection) | 50% | الويب client-side فقط، الموبايل GoRouter redirect |
| إدارة الجلسة (Session) | 80% | كلاهما Supabase، لكن الويب لا يملك middleware |
| التحقق من البريد | 60% | الويب لا يفحص email availability |
| التحقق من رقم الهاتف | 40% | الويب regex عام، الموبايل فحص مصري دقيق |
| Logout | 85% | متشابه |
| **المعدل** | **65%** | |

---

### ملخص التقييم الشامل

| البعد | النسبة | التقييم |
|---|---|---|
| تماثل بصري | 55% | يحتاج تحسين كبير |
| تماثل تخصصي | 65% | متوسط |
| تماثل المكونات | 60% | يحتاج تحسين |
| تماثل وظيفي | 70% | جيد جزئياً |
| تماثل التنقل | 50% | يحتاج تحسين كبير |
| تماثل الرسوم المتحركة | 45% | يحتاج تحسين كبير |
| تماثل التجاوب | 75% | جيد |
| إمكانية الوصول | 55% | يحتاج تحسين |
| الأمان والحالة | 65% | متوسط |
| **المعدل الكلي** | **60%** | **يحتاج تحسين** |

### أولويات التحسين حسب الأثر

| الأولوية | المجال | الأثر المتوقع |
|---|---|---|
| 1 | حل ThemeCubit → توحيد الألوان بين المنصتين | +15% بصري |
| 2 | إصلاح Bottom Nav → floating pill بـ blur 20 | +10% مكونات + تنقل |
| 3 | إصلاح Toast → top-center + colored bg | +8% مكونات + رسوم متحركة |
| 4 | إصلاح ألوان الخلفية والنصوص | +10% بصري + إمكانية وصول |
| 5 | إضافة الصفحات المفقودة (Help, Instructor Profile, Report, Forums Admin) | +12% وظيفي |
| 6 | إصلاح OTP pin boxes + Phone picker في التسجيل | +5% وظيفي + مكونات |
| 7 | إضافة What You'll Learn + FAQ + Sticky Bottom Bar | +5% وظيفي |
| 8 | توحيد الـ Typography tokens | +5% تخصصي |
| 9 | توحيد الشبومر والظلال | +3% بصري |
| 10 | تحسين إمكانية الوصول | +5% إمكانية وصول |
