# Mobile ↔ Web Parity Implementation Roadmap

**Generated:** 2026-06-30  
**Current Parity Score:** 28%  
**Target Parity Score:** 100%  
**Estimated Duration:** 14–18 weeks (3–4 parallel developers)

---

## Executive Summary

The web app has 35 route pages, a working Supabase integration, functional cart/wishlist/auth context, and GSAP animations. However, it suffers from a completely different design system (purple/lime vs. blue primary, Changa/Readex Pro vs. Almarai, Lucide vs. Material Icons), missing shared component library, and 48 missing features.

**Strategy:** Reuse every existing page. Refactor the design tokens first (all pages inherit the fix). Build the shared component library second (all pages adopt it incrementally). Then fix each page from most-user-facing to least. The instructor dashboard is a parallel workstream built last because it's a net-new feature with zero existing code.

**Key Principle:** The design system token change is the highest-leverage action. Updating `globals.css` CSS custom properties immediately fixes colors/border-radius/shadows across ALL 35 pages. This is why it must come first.

---

## Overall Migration Strategy

```
Token Fix (instant global fix)
    ↓
Component Library (shared building blocks)
    ↓
    ├─→ Auth Flow Rewrite (login/register/forgot/verify)
    ├─→ Navigation Rewrite (Header + bottom nav)
    │
    ├──→ Screen Fixes (parallel tracks)
    │    Track A: Home + Course Details + Player
    │    Track B: My Learning + History + Wishlist
    │    Track C: Cart + Checkout + Payments
    │    Track D: Forums + Chat + Q&A
    │    Track E: Profile + Settings + Edit Profile
    │    Track F: Notifications + Search + Categories
    │
    └──→ Instructor Dashboard (parallel track, starts after component library)
    │
States & Animations Layer (applied to all screens)
    ↓
Final QA & Polish
```

---

## Keep / Refactor / Replace / Remove / Add Matrix

### KEEP (Preserve as-is)

| Asset | Reason |
|-------|--------|
| `src/context/AppContext.tsx` | Core state management works; extend don't rewrite |
| `src/lib/supabaseClient.ts` | Supabase client works; just remove hardcoded fallback |
| `src/lib/translations.ts` | Translation structure works; add missing keys |
| `src/components/VideoPlayer.tsx` | YouTube + HTML5 player works; extend controls |
| `src/components/ReviewsSection.tsx` | Review logic works; restyle |
| `src/app/template.tsx` | Page transition wrapper works |
| All Supabase API calls in existing pages | Business logic works; only UI needs changing |
| `/api/paymob/route.ts` | Payment gateway works; add manual payment alongside |
| `/parent-portal/page.tsx` | Feature works; needs UX alignment |
| `/checkout/success/page.tsx` | Polling logic works; add WhatsApp + order ID |
| `/interests/page.tsx` | Core logic works; add min-3 rule + icons |
| `/quiz/page.tsx` | Quiz engine works; restyle + add caching/dialogs |
| `/search/page.tsx` | Search + filter logic works; restyle + add recent |

### REFACTOR (Modify existing code)

| Asset | What Changes |
|-------|-------------|
| `globals.css` | Replace ALL CSS custom properties with mobile AppColors tokens; add Almarai font; remove lime/plasma; fix dark mode to blue palette |
| `layout.tsx` | Update metadata; update font links; adjust structure for bottom nav |
| `Header.tsx` + `Header.module.css` | Reduce to 4 desktop nav items; add notification dot, cart badge, wishlist, history icons; remove lime accents; use Material Icons; add glass styling |
| `page.tsx` (landing) | Refactor logged-in state to use real HomeScreen (not StudentHome) |
| `StudentHome.tsx` + CSS | Refactor into proper HomeScreen with sections (banner carousel, category chips, featured/popular/new/flash sale/recommended/continue learning) |
| `student-features.module.css` | Re-theme all shared styles to match mobile tokens; remove lime accent usage |
| `page.module.css` (landing) | Re-theme; remove 5 stacked redesign layers; consolidate |
| `login/page.tsx` | Add brand header, sliding tab, multi-step register, email verification, hide Apple/Facebook, block instructor, add phone country code, add validation |
| `forgot-password/page.tsx` | Convert to OTP flow |
| `reset-password/page.tsx` | Add URL error parsing, success state |
| `courses/[id]/page.tsx` | Add stats grid, rating distribution, pricing options sheet, share/report |
| `learn/[courseId]/page.tsx` | Add 5-tab system (lectures/more/Q&A/quiz/rating), notes, bookmarks, completion dialog, fullscreen, speed controls |
| `my-learning/page.tsx` | Add filter tabs, continue learning card, recommended section, pagination |
| `cart/page.tsx` | Add instructor+rating rows to cards, collapsible coupon |
| `wishlist/page.tsx` | Expand from minified; add filter tabs, value bar, "Add All to Cart" |
| `notifications/page.tsx` | Expand from minified; add type icons, date grouping, mark-all-read, animations |
| `forums/page.tsx` | Add filter chips, restyle cards |
| `forums/[id]/page.tsx` | Add reactions, reply-to, message options, search |
| `chat/page.tsx` | Add read receipts, reactions, swipe-to-reply |
| `qa/page.tsx` | Add validation rules, instructor highlighting |
| `settings/page.tsx` | Add WhatsApp help card, move language toggle in |
| `payments/page.tsx` | Add 5-tab filtering, payment detail sheet |
| `history/page.tsx` | Expand from minified; switch to lesson-centered model |
| `context/AppContext.tsx` | Add `unreadNotifications`, `streakCount` to profile; add toast/utility methods |
| `lib/animations.ts` | Add `useSlideFadeIn`, `useScaleIn`, `useStaggeredList`, pulse/shake CSS animations |

### REPLACE (Swap with new implementation)

| Asset | Reason |
|-------|--------|
| Font import in `globals.css` | Replace Readex Pro/Plus Jakarta Sans/Changa with Almarai |
| All Lucide icon imports across all files | Replace with `@mui/icons-material` or `material-icons` npm package |
| `.gradient-text` CSS (purple gradient) | Replace with mobile's blue gradient or solid primary |
| `.gradient-bg` CSS (purple+lime) | Replace with primary-only gradient matching mobile |
| `window.confirm()` in quiz | Replace with custom `ResponsiveDialog` component |
| `FeaturePageHero.tsx` | Replace with mobile-matching section headers (not lime accent hero cards) |
| Inline HTML5 validation on forms | Replace with custom validation matching mobile Arabic/English messages |

### REMOVE (Delete from web)

| Asset | Reason |
|-------|--------|
| `--accent` / `--accent-ink` CSS vars | Lime accent doesn't exist in mobile |
| `--plasma` / `--plasma` CSS vars | Plasma color doesn't exist in mobile |
| Apple & Facebook login buttons | Mobile hides these: `showApple: false` |
| Instructor role selector on sign-up | Mobile blocks instructor registration |
| `Changa` font import | Mobile uses only Almarai |
| Lime/`var(--accent)` from all button/CSS backgrounds | Replace with primary blue |
| Purple gradient dark mode tokens | Replace with blue dark mode tokens |
| `.ambient-background` decorative circles | Not in mobile; remove the lime/purple orbs |
| Purple-tinted shadow variables | Replace with neutral shadows |
| Marketing landing hero (for logged-in users) | Logged-in users should see mobile's HomeScreen layout |

### ADD (New code needed)

| Asset | Purpose |
|-------|---------|
| `src/components/ui/` directory | Shared component library (AppButton, AppCard, AppTextField, GlassSearchBar, GlassIconButton, EmptyState, ErrorState, LoadingState, ResponsiveDialog, SectionHeader, UserAvatar, RatingStars, PriceTag, AppBackButton, PhoneInputField, ShimmerEffect, Toast, BottomNavBar) |
| `src/lib/designTokens.ts` | Typed JS object mirroring AppColors, AppTextStyles, AppSpacing, AppRadius |
| `src/lib/validators.ts` | Arabic/English validation functions matching mobile |
| `src/lib/toast.ts` | Toast utility matching mobile's ToastUtils |
| `src/lib/formatters.ts` | Number/count/time-ago formatting matching mobile |
| `/profile/page.tsx` | New separate profile page with stats + menu |
| `/edit-profile/page.tsx` | New edit profile page with avatar upload + fields |
| `/categories/page.tsx` | New categories grid page |
| `/report/page.tsx` | New report screen with reason chips |
| `/instructor/` directory (14+ pages) | New instructor dashboard with all tabs |
| Banner carousel component | For home page |
| Flash sale section component | For home page |
| Course card variants | VerticalCard, HorizontalCard, EnhancedCard |
| Message reaction picker | For forums + chat |
| Swipe-to-reply handler | For forums + chat |
| Read receipts component | For direct chat |
| Rating distribution chart | For course details + player rating tab |
| Pricing options bottom sheet | For course details |
| Course completion dialog | For player |
| Mini video player overlay | For app-level use |
| Answer cache (localStorage) | For quizzes |
| Connectivity detection hook | For offline indicator |
| OTP input component | For forgot password flow |
| Country code selector | For registration phone field |
| Multi-step form wizard | For registration |

---

## Feature Implementation Order

Ordered by dependency chain and impact:

| Order | Feature | Rationale |
|-------|---------|-----------|
| 1 | Design tokens (CSS custom properties) | Every screen inherits the fix instantly |
| 2 | Almarai font | Brand identity — needed before any screen is "correct" |
| 3 | Material Icons package | Needed by every component and screen |
| 4 | Shared component library | All screens depend on these |
| 5 | Toast + validator utilities | Auth + all forms depend on these |
| 6 | Navigation (Header + bottom nav) | Used on every page |
| 7 | Auth flow (login/register/forgot/verify) | Gateway to the app — user-facing first |
| 8 | Home page (logged-in) | Most visited page after auth |
| 9 | Profile page | Referenced from nav and settings |
| 10 | Course details | Core content page |
| 11 | Course player | Core content consumption |
| 12 | My Learning | Second most visited for enrolled users |
| 13 | Search + Categories | Discovery paths |
| 14 | Cart + Checkout + Payments | Conversion flow |
| 15 | Wishlist + History | Secondary pages |
| 16 | Notifications | Engagement |
| 17 | Forums + Chat + Q&A | Community features |
| 18 | Settings + Edit Profile | Account management |
| 19 | Instructor Dashboard | Net-new feature, separate user role |
| 20 | Animations + States layer | Polish pass across all screens |
| 21 | Final QA | Verification |

---

## Screen Implementation Order

### Must Fix First (derived from token + component changes)
1. `globals.css` — token replacement (affects ALL screens)
2. `layout.tsx` — font + meta update
3. All CSS modules — remove lime/plasma references

### Then Screen-by-Screen (in user-journey order)
1. `/login` → 2. `/forgot-password` → 3. `/reset-password` → 4. `/interests`
5. `/` (home for logged-in) → 6. `/profile` → 7. `/settings`
8. `/edit-profile` (new) → 9. `/categories` (new)
10. `/search` → 11. `/courses/[id]`
12. `/learn/[courseId]`
13. `/my-learning`
14. `/cart` → 15. `/checkout` → 16. `/checkout/success` → 17. `/payments`
18. `/wishlist` → 19. `/history`
20. `/notifications`
21. `/forums` → 22. `/forums/[id]` → 23. `/chat` → 24. `/qa`
25. `/quiz/[id]`
26. `/report` (new)
27. `/parent-portal`
28. `/privacy` → 29. `/terms`
30. `/instructor/*` (14 sub-pages — new)

---

## Component Implementation Order

| Order | Component | Depends On |
|-------|-----------|------------|
| 1 | `AppButton` | Design tokens |
| 2 | `AppCard` | Design tokens |
| 3 | `AppTextField` | Design tokens, AppButton |
| 4 | `AppBackButton` | Design tokens |
| 5 | `GlassSearchBar` | Design tokens |
| 6 | `GlassIconButton` | Design tokens |
| 7 | `ShimmerEffect` | Design tokens |
| 8 | `EmptyState` | ShimmerEffect, animations |
| 9 | `ErrorState` | AppButton, AppCard, animations |
| 10 | `LoadingState` | ShimmerEffect |
| 11 | `ResponsiveDialog` | AppCard, AppButton |
| 12 | `SectionHeader` | Design tokens |
| 13 | `UserAvatar` | Design tokens |
| 14 | `RatingStars` | Design tokens |
| 15 | `PriceTag` | Design tokens |
| 16 | `Toast` | Design tokens |
| 17 | `BottomNavBar` | Material Icons, GlassSearchBar patterns |
| 18 | `BannerCarousel` | AppCard, animations |
| 19 | `CourseCard` (vertical) | AppCard, PriceTag, RatingStars, UserAvatar |
| 20 | `CourseCard` (horizontal) | Same as above |
| 21 | `PhoneInputField` | AppTextField |
| 22 | `OtpInputField` | AppTextField |
| 23 | `FilterChips` | AppButton |
| 24 | `RatingDistribution` | RatingStars |
| 25 | `ReactionPicker` | ResponsiveDialog |
| 26 | `MessageBubble` | AppCard, UserAvatar, ReactionPicker |
| 27 | `MiniPlayerOverlay` | AppCard, animations |

---

## Phase Definitions

---

### Phase 0: Design Token Migration

**Objective:** Replace the entire CSS custom property system in `globals.css` to match mobile's `AppColors`, `AppRadius`, `AppSpacing`, and `AppShadows`. Load Almarai font. Install Material Icons.

**Why this phase comes now:** This is the highest-leverage change. Modifying CSS custom properties instantly affects ALL 35 pages. Every subsequent phase builds on top of correct tokens. Without this, every visual fix would need to be redone.

**Features included:**
- Replace all `:root` CSS variables with mobile AppColors values
- Replace all `[data-theme="dark"]` CSS variables with mobile dark mode values
- Add Almarai font via Google Fonts CDN (weights 300/400/500/600/700/800)
- Remove Changa, Readex Pro, Plus Jakarta Sans font imports
- Install `@mui/icons-material` (or `material-icons`) npm package
- Replace `--radius-*` with mobile's AppRadius values
- Replace `--shadow-*` with neutral (not purple-tinted) shadows
- Remove `--accent`, `--accent-ink`, `--plasma` variables
- Add `--primary-on-dark: #93C5FD` variable
- Add missing tokens: `--card-dark: #172033`, `--surface-dark: #0F172A`, etc.
- Add typography scale tokens matching mobile's AppTextStyles
- Add spacing scale tokens matching mobile's 8px grid
- Add rating color token `--rating: #B47D00`
- Remove `.ambient-background` orb elements from `layout.tsx`
- Update `layout.tsx` metadata from "Chemistry platform" to "Shahab Tech"

**Screens affected:** ALL (via CSS variable inheritance)

**Components affected:** ALL (via CSS variable usage)

**APIs affected:** None

**Existing code reused:** `globals.css` structure (just value replacement), `layout.tsx` structure

**Existing code refactored:** `globals.css` (token values), `layout.tsx` (metadata, font link, remove ambient div), dark mode block in `globals.css`

**New work required:**
- Google Fonts Almarai import URL
- `src/lib/designTokens.ts` — typed JS constants mirroring CSS vars for use in JSX
- Material Icons package installation and configuration

**Risks:**
- **Medium:** Removing lime accent will break visual hierarchy on many pages that use `var(--accent)` for CTAs. All `var(--accent)` references must be replaced with `var(--primary)` simultaneously.
- **Low:** Almarai may have different metrics than current fonts; some layouts may need minor spacing adjustments.

**Estimated complexity:** Medium (mechanical replacement, but large surface area)

**QA checklist:**
- [ ] Light mode: all surfaces, text, borders match mobile's `AppColors` light values
- [ ] Dark mode: primary is `#2563EB` / `#93C5FD` (not purple)
- [ ] No lime/chartreuse color visible anywhere
- [ ] Almarai font renders on all text
- [ ] Border radius values match mobile's AppRadius scale
- [ ] Shadows are neutral (not purple-tinted)
- [ ] Material Icons render correctly

**Acceptance criteria:**
- CSS custom properties match mobile's AppColors 1:1
- Dark mode uses blue palette, not purple
- Almarai is the only font family rendered
- No remaining references to `--accent`, `--plasma`, `Readex Pro`, `Plus Jakarta Sans`, `Changa`

**Definition of Done:** Visual diff of any page in light/dark mode shows correct mobile colors and Almarai font; no lime/purple visible.

---

### Phase 1: Icon Migration

**Objective:** Replace all Lucide React icons with Material Icons across the entire codebase.

**Why this phase comes now:** Icons are used in every component and page. Must be done before building shared components (which will use Material Icons). Doing it after tokens means the new colors will already be correct, so only icon names need replacing.

**Features included:**
- Install `@mui/icons-material` package
- Create mapping file: Lucide name → Material Icon name
- Replace all `import { ... } from 'lucide-react'` in every file
- Update icon sizing to match mobile's scale (xs=12, sm=14, md=18, lg=24)
- Update icon style from outline to filled/rounded where mobile uses filled
- Remove `lucide-react` from `package.json`

**Screens affected:** ALL pages that import Lucide icons (Header, login, search, courses, quiz, cart, checkout, settings, forums, chat, notifications, wishlist, history, payments, etc.)

**Components affected:** Header.tsx, FeaturePageHero.tsx, StudentHome.tsx, VideoPlayer.tsx, all page.tsx files

**APIs affected:** None

**Existing code reused:** All page structures (only import lines + JSX icon references change)

**Existing code refactored:** Every file importing from `lucide-react`

**New work required:**
- Icon mapping reference file
- Uninstall lucide-react

**Risks:**
- **Medium:** Not every Lucide icon has a 1:1 Material equivalent. Some icons (e.g., `FlaskConical`) need manual selection of closest Material equivalent.
- **Low:** Sizing differences may require adjusting some layouts.

**Estimated complexity:** Medium (tedious but mechanical)

**QA checklist:**
- [ ] No `lucide-react` import in any file
- [ ] All icons are Material Icons
- [ ] Icon sizes match mobile's scale
- [ ] Icon styles match mobile (filled vs outline)
- [ ] No broken/missing icon renders

**Acceptance criteria:**
- `grep -r "lucide-react" src/` returns zero results
- All icons visible and matching mobile icon choices

**Definition of Done:** Zero Lucide references; all icons render as Material Icons matching mobile's icon choices.

---

### Phase 2: Shared Component Library

**Objective:** Build a reusable component library in `src/components/ui/` that mirrors the mobile app's shared widgets. Every subsequent screen refactor will use these components instead of ad-hoc styling.

**Why this phase comes now:** Phase 0+1 fixed the visual foundation (tokens + icons). Now we need the building blocks. Every screen refactor depends on having correct AppButton, AppCard, AppTextField, etc. Building them now avoids duplicating styling logic across 35 pages.

**Features included:**
- `AppButton` — 6 variants (primary, secondary, outline, text, success, error), 3 sizes (small/medium/large), press scale animation, loading spinner, icon support, full-width option
- `AppCard` — 3 variants (elevated, outlined, filled), glass glow shadow, press animation, configurable radius
- `AppTextField` — label (above), validation, focus glow animation, prefix icon, border radius 12
- `AppBackButton` — container + arrow icon, fallback navigation
- `GlassSearchBar` — blur backdrop, 1.5px border, search icon, clear button, filter icon
- `GlassIconButton` — blur backdrop, 1.5px border, badge/notification dot support
- `ShimmerEffect` — CSS animation shimmer wrapper (1500ms loop)
- `EmptyState` — 17 type variants, animation (fade+scale+slide 800ms), compact mode
- `ErrorState` — 5 type variants, 3 display densities, retry + go-back buttons
- `LoadingState` — 3 display densities (fullPage/section/compact), spinner + message
- `ResponsiveDialog` — mobile/tablet/desktop width logic, dark/light, barrier 0.7 black, title + content + actions
- `Toast` — success/error/warning/info types, floating, auto-dismiss
- `SectionHeader` — title 18px w700, subtitle, action text + arrow
- `UserAvatar` — 5 sizes (xs/sm/md/lg/xl), border, initials fallback, verified badge
- `RatingStars` — 4 sizes (xs/sm/md/lg), half-star support, interactive mode
- `PriceTag` — 3 sizes, free label, discount badge, strikethrough
- `FilterChips` — horizontal scroll, animated selection, count badges
- `BottomNavBar` — 4 tabs, glass backdrop, pill selector, Material Icons

**Screens affected:** None yet (components built in isolation)

**Components affected:** New directory `src/components/ui/`

**APIs affected:** None

**Existing code reused:**
- `GlassSearchBar` pattern from mobile's `glass_search_bar.dart`
- `GlassIconButton` pattern from mobile's `glass_icon_button.dart`
- GSAP animation patterns from existing `src/lib/animations.ts`
- CSS glass effect from existing `.glass` class

**Existing code refactored:** None (new files)

**New work required:**
- 18 component files in `src/components/ui/`
- Each with accompanying `.module.css` or Tailwind styles
- `src/components/ui/index.ts` barrel export

**Risks:**
- **Low:** Components are isolated; can be built and tested independently.
- **Low:** Press animations (scale on click) require careful CSS/React coordination.

**Estimated complexity:** High (many components, but each is self-contained)

**QA checklist:**
- [ ] Each component renders in light/dark mode
- [ ] Each component renders in RTL (Arabic) and LTR (English)
- [ ] AppButton: all 6 variants × 3 sizes, loading state, disabled state, press animation
- [ ] AppCard: all 3 variants, glass glow, hover effect
- [ ] AppTextField: label, hint, error, focus glow, prefix icon, RTL
- [ ] EmptyState: all 17 types, animation, compact mode
- [ ] ErrorState: all 5 types × 3 densities, retry callback
- [ ] ResponsiveDialog: widths on mobile/tablet/desktop, destructive variant
- [ ] BottomNavBar: 4 tabs, pill animation, active state
- [ ] All sizes for RatingStars, UserAvatar, PriceTag match mobile pixel values

**Acceptance criteria:**
- All 18 components exist, documented, and tested in isolation (Storybook or test page)
- Components use only design tokens (no hardcoded colors/sizes)
- Components handle RTL/LTR and dark/light mode

**Definition of Done:** Component library renders correctly in all modes; can be imported and used in any page.

---

### Phase 3: Utility Layer

**Objective:** Build validation, formatting, and toast utilities that match mobile's behavior. These are used by auth forms, course details, cart, and throughout.

**Why this phase comes now:** Auth flow (next phase) depends on validators and toasts. Building utilities first means auth pages can use them immediately.

**Features included:**
- `src/lib/validators.ts` — Arabic/English validators: email (regex), password (min 8), confirm match, required, phone regex, name required
- `src/lib/toast.ts` — showSuccess, showError, showWarning, showInfo — floating, auto-dismiss, colored backgrounds matching mobile's AnimatedSnackbar
- `src/lib/formatters.ts` — count formatting (1.5K, 1.5M), time-ago (just now, Xm, Xh, Xd), date grouping (Today/Yesterday/date), currency (EGP/ج.م), duration (Xh Ym)
- `src/lib/hooks/useOnlineStatus.ts` — connectivity detection for offline indicator

**Screens affected:** None yet (utilities are consumed by pages in later phases)

**Components affected:** None

**APIs affected:** None

**Existing code reused:** `src/lib/translations.ts` structure (extend with new keys)

**Existing code refactored:** `translations.ts` — add missing keys for auth errors, quiz, forums, chat, etc.

**New work required:** 4 new files

**Risks:** Low

**Estimated complexity:** Low

**QA checklist:**
- [ ] Validators return Arabic message for Arabic lang, English for English lang
- [ ] Toast renders with correct colors (success=green, error=red, etc.)
- [ ] Count formatter: 999→999, 1000→1.0K, 1000000→1.0M
- [ ] Time-ago: "just now", "5m ago", "3h ago", "2d ago"
- [ ] Online status hook detects offline/online transitions

**Acceptance criteria:** All utilities work and match mobile's output strings.

**Definition of Done:** Utilities unit-tested; translation keys complete.

---

### Phase 4: Authentication Flow

**Objective:** Rewrite login, register, forgot-password, reset-password, and interests to match mobile exactly. Add email verification flow. Add OTP-based password reset.

**Why this phase comes now:** This is the user's first interaction with the app. It depends on design tokens (Phase 0), Material Icons (Phase 1), shared components (Phase 2), and validators/toasts (Phase 3). All dependencies are now ready.

**Features included:**

**4a. Login page (`/login`):**
- Add gradient brand header "شهاب Tech" / "Shahab Tech" with ShaderMask gradient
- Replace text toggle with sliding pill AuthTabBar (AnimatedAlign, 300ms, easeOutBack)
- Replace all inputs with `AppTextField` (label above, prefix icon, border radius 12, cardDark/white fill)
- Remove Apple & Facebook social login buttons — show Google only
- Remove Instructor role selector — block instructor registration
- Add "Forgot Password?" TextButton aligned to end
- Add custom validation messages (Arabic/English) using validators
- Add loading spinner in submit button

**4b. Multi-Step Registration (within `/login`):**
- Stage 1: Name field → Next
- Stage 2: Email + Phone (with country code selector, +20 default) → Next
- Stage 3: Password + Confirm Password → Next
- Stage 4: Profile Photo picker (optional) → Create Account
- Progress indicator at top of each stage
- Back/Next/Create navigation buttons matching mobile
- Email availability check on Stage 2

**4c. Email Verification:**
- After register, if session is null (email verification needed):
  - Show inline verification card with mail icon, email display, instruction text
  - "Done, go to login" primary button
  - "Resend email" outlined button
- Call Supabase `resend(type: signup, email)`

**4d. Forgot Password (`/forgot-password`):**
- Phase 1: Enter email → "Send Reset Code" button
  - Uses `supabase.auth.signInWithOtp(email, shouldCreateUser: false)`
- Phase 2: Enter OTP code + new password + confirm password → "Verify and Change Password"
  - Uses `supabase.auth.verifyOTP(type: email)` then `updateUser({password})`
  - Then `signOut()` and redirect to `/login`
- Add "Resend Code" TextButton
- Header icon: 80x80 circle with `mark_email_unread_rounded` icon

**4e. Interests page (`/interests`):**
- Add minimum 3 selection requirement (button disabled otherwise)
- Add per-category Material icons
- Match chip animation (animated container 200ms)
- Update save button to show "Continue (N selected)"
- Add suggest topic dialog

**Screens affected:** `/login`, `/forgot-password`, `/reset-password`, `/interests`

**Components affected:** AppTextField, AppButton, GlassIconButton, ResponsiveDialog, PhoneInputField (new), OtpInputField (new)

**APIs affected:**
- `supabase.auth.signInWithOtp` (new — OTP flow)
- `supabase.auth.verifyOTP` (new)
- `supabase.auth.resend` (new — email verification)
- `supabase.auth.updateUser` (existing)

**Existing code reused:**
- `/login/page.tsx` structure (form, state management, Supabase calls)
- `/forgot-password/page.tsx` structure
- `/reset-password/page.tsx` structure
- `/interests/page.tsx` fetch + save logic

**Existing code refactored:**
- `/login/page.tsx` — major restructure for multi-step + email verification + phone selector
- `/forgot-password/page.tsx` — convert from magic link to OTP flow
- `/interests/page.tsx` — add min-3 rule, category icons

**New work required:**
- `PhoneInputField` component
- `OtpInputField` component
- Multi-step wizard wrapper component
- Email verification inline view
- Country code data (dial codes + flags)

**Risks:**
- **Medium:** OTP-based password reset requires Supabase `signInWithOtp` with `shouldCreateUser: false`. This is different from the current magic link flow. Backend email templates may need updating to send OTP codes instead of magic links.
- **Low:** Multi-step form state management is more complex than single-page.

**Estimated complexity:** High (auth is security-critical + multiple flows)

**QA checklist:**
- [ ] Login: brand header renders with gradient
- [ ] Login: sliding pill tab switches between login/register
- [ ] Login: only Google social button visible
- [ ] Login: instructor role not selectable
- [ ] Register: 4 stages progress correctly
- [ ] Register: phone input shows country code selector with +20 default
- [ ] Register: email availability checked in real-time
- [ ] Register: on success → email verification view or interests
- [ ] Email verification: resend button works
- [ ] Forgot password: Phase 1 sends OTP, Phase 2 verifies + resets
- [ ] Forgot password: "Resend Code" works
- [ ] Interests: minimum 3 enforced, button disabled below 3
- [ ] All validation messages appear in Arabic/English matching mobile

**Acceptance criteria:**
- Auth flow matches mobile screen-by-screen
- OTP-based password reset works end-to-end
- Email verification flow works
- Instructor registration is blocked
- Only Google login shown

**Definition of Done:** Full auth journey from login → register → verify email → interests → home works and matches mobile.

---

### Phase 5: Navigation

**Objective:** Refactor the Header and add mobile-matching bottom navigation for logged-in users. Add quick action buttons matching mobile.

**Why this phase comes now:** Navigation is visible on every page. It depends on design tokens, Material Icons, and Glass components. Auth flow is already fixed, so navigation destinations are correct.

**Features included:**

**5a. Desktop Header (`Header.tsx`):**
- Update nav items: Home, Courses, My Learning, Community, Exams → match mobile's 4 tabs mapped for desktop
- Add to actions row: notification bell (with unread dot), cart (with badge count), wishlist icon, history icon
- Replace Lucide icons with Material Icons
- Remove lime accent from all buttons
- Add glass backdrop effect matching mobile's app bar

**5b. Mobile Bottom Navigation:**
- Replace 5-tab mobile nav with 4-tab: Home, My Learning, Forums, Profile
- Use Material Icons: `Home`, `PlayCircle`, `Forum`, `Person`
- Active state: primary pill bg with border (animated container, 200ms)
- Glass backdrop: `backdrop-filter: blur(20px)`, `border-radius: 40`, semi-transparent bg
- Selected icon color: `var(--primary)`, unselected: `var(--text-muted)`

**5c. Quick Actions (in Header):**
- Notification bell: 44x44 glass icon button, red dot when unread
- Cart: 44x44 glass icon button, red badge with count
- Remove language toggle from header (moves to settings)
- Theme toggle stays in header
- User avatar/name with dropdown

**Screens affected:** ALL (layout.tsx wraps all pages with Header)

**Components affected:** Header.tsx, Header.module.css, BottomNavBar (new)

**APIs affected:** None

**Existing code reused:** Header.tsx structure, existing responsive breakpoint logic

**Existing code refactored:**
- `Header.tsx` — remove 5-tab mobile nav, add 4-tab with glass styling, add notification/cart badges
- `Header.module.css` — re-theme glass, add pill selector styles, remove lime

**New work required:**
- `BottomNavBar` component in `src/components/ui/`
- Unread notification count integration from AppContext

**Risks:**
- **Low:** Changing tab count from 5 to 4 is a visible but low-risk structural change.

**Estimated complexity:** Medium

**QA checklist:**
- [ ] Desktop: nav items match mobile's labeled tabs
- [ ] Desktop: notification bell shows red dot when unread
- [ ] Desktop: cart shows badge with count
- [ ] Mobile: 4-tab bottom nav with glass effect
- [ ] Mobile: tab switching animates pill selector 200ms
- [ ] Active tab: primary pill bg + border + primary icon
- [ ] All icons are Material Icons

**Acceptance criteria:**
- Navigation matches mobile's 4-tab structure
- Glass backdrop effect renders on bottom nav
- Cart badge and notification dot work

**Definition of Done:** Nav renders correctly on desktop and mobile with mobile-matching tabs, icons, and styling.

---

### Phase 6: Home Page

**Objective:** Replace the StudentHome component with a mobile-matching home screen layout including all sections.

**Why this phase comes now:** Home is the most visited page after auth. It depends on navigation (Phase 5 — the page is reached via nav), shared components (course cards, section headers, banners), and design tokens.

**Features included:**
- Keep landing page for guests (refactor to remove lime/plasma)
- Replace logged-in `StudentHome` with mobile-matching HomeScreen:
  - **Hero/search area:** Collapsible header with greeting (user name), GlassSearchBar (height 46, tune icon, navigate to /search)
  - **Banner Carousel:** PageView with auto-scroll (5s), gradient overlay, animated dot indicators
  - **Category Chips:** Horizontal scrolling chips with icons, "All" first, animated selection
  - **Flash Sale Section:** Red gradient header with countdown timer, horizontal course cards
  - **Featured Courses:** Horizontal card list with "See All" link
  - **Popular Courses:** Horizontal card list
  - **New Arrivals:** Vertical card list
  - **Recommended:** AI badge header, horizontal cards
  - **Continue Learning:** Dedicated card(s) with thumbnail, progress bar, "CONTINUE LEARNING" label, resume button
  - **Parent Portal Card:** Family icon, primary bg, enter button
- **Course Card (vertical):** thumbnail, badges (free/discount/custom), wishlist heart, title, instructor, rating + enrolled count, price
- **Course Card (horizontal):** wider layout, more detail
- **Shimmer loading skeleton:** match mobile's multi-section skeleton

**Screens affected:** `/` (page.tsx)

**Components affected:** StudentHome.tsx → refactored, new BannerCarousel, FlashSaleSection, CategoryChips, CourseCardVertical, CourseCardHorizontal, ContinueLearningCard

**APIs affected:**
- Existing Supabase queries for courses (reuse)
- New query for banners: `supabase.from('banners').select('*')`
- Existing enrollments query for continue learning

**Existing code reused:**
- `StudentHome.tsx` structure (greeting, course fetching)
- Course card thumbnail rendering logic
- Cart/wishlist toggle logic via AppContext

**Existing code refactored:**
- `StudentHome.tsx` — add sections, replace quick access grid
- `page.tsx` — keep guest landing, fix logged-in rendering
- CSS modules — remove lime, add new section styles

**New work required:**
- Banner carousel component with auto-scroll
- Flash sale section with countdown timer
- Category chips horizontal scroll
- Course card vertical/horizontal variants
- Continue learning card component
- Shimmer skeleton matching home layout
- Banners data fetch

**Risks:**
- **Medium:** Banner carousel auto-scroll needs careful implementation (timer + cleanup)
- **Low:** Flash sale countdown is similar to existing quiz timer

**Estimated complexity:** High (many visual sections, multiple new components)

**QA checklist:**
- [ ] Guest landing page renders without lime/plasma colors
- [ ] Logged-in home shows: greeting, search bar, banners, categories, flash sale, featured, popular, new, recommended, continue learning, parent portal
- [ ] Banner auto-scrolls every 5 seconds with dot indicators
- [ ] Category chips scroll horizontally with "All" first
- [ ] Flash sale countdown timer ticks correctly
- [ ] Course cards show thumbnail, title, instructor, rating, price, wishlist, add-to-cart
- [ ] Continue learning card shows progress bar + resume button
- [ ] Shimmer skeleton appears while loading
- [ ] Dark mode renders correctly on all sections

**Acceptance criteria:**
- Home screen matches mobile's section order and content
- All sections render with mobile-matching styling
- Loading state shows shimmer skeleton

**Definition of Done:** Logged-in home is visually indistinguishable from mobile (structure, sections, cards, interactions).

---

### Phase 7: Profile + Settings + Edit Profile

**Objective:** Create the separate Profile page (currently redirects to settings). Add the Edit Profile page. Align Settings to mobile layout.

**Why this phase comes now:** Profile is a nav tab destination (Phase 5 links to it). It's a medium-complexity screen that unblocks user account management.

**Features included:**

**7a. Profile page (`/profile`):**
- Header: avatar (4px border, primary), name (22px bold), email (14px muted)
- Stats section: card with Courses count + Streak count + divider
- Menu items card: Instructor Dashboard (conditional), Edit Profile, Notifications, My Learning, Orders Status (حالة الطلبات), Forums (المنتديات), Wishlist, Settings
  - Each: Material Icon 22px primary + 14px gap + title 15px + chevron_right
- Logout button: full-width OutlinedButton with error color/border

**7b. Edit Profile page (`/edit-profile`):**
- Avatar section: camera overlay button, "Change Avatar" text
- Cover image section (instructor only)
- Name field, Phone field (with country code selector)
- Instructor fields (if role=instructor): Display Name, Headline AR/EN, Bio AR/EN, Expertise, Website, Social Links (Facebook, Twitter, LinkedIn, YouTube)
- Save button in AppBar
- Image upload to Supabase Storage `avatars` bucket

**7c. Settings page (`/settings`):**
- Preferences card: Language (ExpansionTile with AR/EN), Dark Mode (Switch), Notifications (Switch)
- Legal & Support: Help Center (ExpandableCard → WhatsApp card with gradient), Privacy Policy, Terms of Service
- Delete Account (AnimatedButton, error color, confirmation dialog)
- Version "2.4.0"
- Remove language toggle from Header (now in Settings)

**Screens affected:** `/profile` (new), `/edit-profile` (new), `/settings`

**Components affected:** AppButton, AppCard, AppTextField, UserAvatar, AppBackButton, ResponsiveDialog, PhoneInputField

**APIs affected:**
- `supabase.from('profiles').update()` for profile save
- `supabase.storage.from('avatars').upload()` for image upload

**Existing code reused:** `/settings/page.tsx` structure and logic (theme toggle, logout, etc.)

**Existing code refactored:** `/settings/page.tsx` — add WhatsApp help card, add language ExpansionTile, restyle with AppCard/AppButton

**New work required:**
- `/profile/page.tsx` — new page
- `/edit-profile/page.tsx` — new page with image upload
- Instructor social links form section

**Risks:**
- **Medium:** Image upload to Supabase Storage needs proper cache-busting and error handling
- **Low:** Profile page is mostly static content

**Estimated complexity:** Medium

**QA checklist:**
- [ ] Profile shows avatar, name, email, stats, menu items
- [ ] Instructor Dashboard link appears only for instructor/admin role
- [ ] Logout shows confirmation dialog
- [ ] Edit Profile: avatar upload works, saves to Storage
- [ ] Edit Profile: instructor fields appear only for instructors
- [ ] Edit Profile: save button works, shows spinner while saving
- [ ] Settings: language toggle is here (not in header)
- [ ] Settings: WhatsApp help card with gradient renders
- [ ] Settings: delete account shows confirmation dialog

**Acceptance criteria:**
- Profile page matches mobile layout with stats + menu
- Edit profile works for avatar upload and all fields
- Settings matches mobile structure

**Definition of Done:** Profile, Edit Profile, and Settings match mobile visually and functionally.

---

### Phase 8: Course Details + Search + Categories

**Objective:** Enhance course details page with mobile-matching sections. Improve search with recent searches and full-page filter. Add categories page.

**Why this phase comes now:** Course details is the core content page that drives enrollment. Search and categories are discovery paths. These depend on course card components (built in Phase 6).

**Features included:**

**8a. Course Details (`/courses/[id]`):**
- Add 2x2 Stats Grid: Lessons, Hours, Quizzes, Certificate (with icons)
- Add Rating Distribution: 5-bar horizontal chart (1-5 stars with percentage bars)
- Add Pricing Options Bottom Sheet (if multiple pricing options)
- Add Share + Report buttons (via PopupMenu or dropdown)
- Refactor curriculum section: add type icons (play/article/quiz), lock icons for unpaid, preview badges
- Match "What You Learn" container styling with check icons
- Ensure CTA states in sidebar match mobile's bottom bar logic (Add to Cart / Continue Learning / Get for Free / Go to Cart)

**8b. Search (`/search`):**
- Add Recent Searches section (localStorage, clear all button, search chips)
- Add Categories chip section (from Supabase)
- Replace filter dropdowns with bottom sheet matching mobile's CourseFilterScreen
- Add sort options (relevance, newest, highest rated, etc.)
- Add price range slider
- Add level + rating filter chips

**8c. Categories (`/categories`):**
- New page: 2-column GridView with 10 hardcoded categories
- Each card: 56x56 icon container (category color at 15% alpha), icon 28px, category name, course count
- Category icons matching mobile's mapping
- Tap navigates to `/search?category=ID`

**8d. Course Search Filter Screen:**
- Full-page filter with categories (multi-select chips), price range slider, level chips, rating options
- Clear Filters + Apply buttons

**Screens affected:** `/courses/[id]`, `/search`, `/categories` (new), `/search/filter` (new)

**Components affected:** AppCard, RatingStars, RatingDistribution (new), PricingOptionsSheet (new), CourseFilterSheet (new)

**APIs affected:** Existing course fetch queries (reuse)

**Existing code reused:**
- `/courses/[id]/page.tsx` — layout, data fetching, curriculum accordion
- `/search/page.tsx` — filter logic, course grid rendering
- ReviewsSection component

**Existing code refactored:**
- `/courses/[id]/page.tsx` — add stats grid, rating distribution, pricing sheet, share/report
- `/search/page.tsx` — add recent searches, categories, refactor filters to bottom sheet

**New work required:**
- RatingDistribution component
- PricingOptionsSheet component
- Share utility (navigator.share or clipboard)
- Report page/screen integration
- Categories page
- Course filter bottom sheet component
- Recent searches localStorage hook

**Risks:**
- **Low:** Course details enhancements are additive
- **Medium:** Pricing options bottom sheet requires understanding `pricingOptions` data structure

**Estimated complexity:** Medium

**QA checklist:**
- [ ] Stats grid: 4 cards with icons (Lessons, Hours, Quizzes, Certificate)
- [ ] Rating distribution: 5-bar chart with percentages
- [ ] Pricing options sheet opens with course pricing options
- [ ] Share + Report buttons work
- [ ] Curriculum items show type icons + lock + preview badge
- [ ] Search: recent searches appear and can be cleared
- [ ] Search: filter bottom sheet has all options
- [ ] Categories: 10 categories with icons and course counts
- [ ] Category tap navigates to search with filter applied

**Acceptance criteria:**
- Course details matches mobile's sections
- Search has recent searches + full filter
- Categories page matches mobile

**Definition of Done:** Course details, search, and categories match mobile.

---

### Phase 9: Course Player Overhaul

**Objective:** Restructure the course player to match mobile's 5-tab system. Add notes, bookmarks, video improvements, course completion, and Q&A/rating tabs.

**Why this phase comes now:** The course player is the most complex screen. It depends on course data fetching (already works), video player (already works), and shared components. This is a large refactor that builds on the existing `/learn/[courseId]` structure.

**Features included:**
- **5-tab sticky tab bar:** Lectures (curriculum), More (notes/bookmarks/announcements/attachments), Q&A, Quizzes, Rating
- **Video improvements:** playback speed selector (0.5x–2x), fullscreen button, keyboard shortcuts, improved controls
- **Notes tab:** Add note (4-line text field), list notes with timestamp badges, delete notes
- **Bookmarks tab:** List bookmarks with "Go to Lesson" navigation, delete bookmarks
- **Q&A tab:** Ask question form, question list, answer list with instructor highlighting
- **Quizzes tab:** Lesson quiz links, course quiz links, quiz status icons
- **Rating tab:** Rating distribution, write review form, review cards
- **Course completion:** When all lessons complete, show CompletionAnimation (trophy) + certificate info dialog
- **Bottom action bar:** "Next Lesson" primary button + "Resources" outlined button
- **Lesson type renderers:** Improve article display (no dangerouslySetInnerHTML without sanitization), add document viewer, assignment UI
- **Attachment preview:** File type icons, download/open functionality
- **Fullscreen video:** Escape to return, custom controls
- **Answer caching for quizzes (in player context):** localStorage per quiz ID

**Screens affected:** `/learn/[courseId]`

**Components affected:** VideoPlayer.tsx (enhance), ResponsiveDialog (completion dialog), QATab (new), RatingTab (new), NotesTab (new), BookmarksTab (new), QuizzesTab (new)

**APIs affected:**
- `supabase.from('notes')` — new CRUD
- `supabase.from('bookmarks')` — new CRUD
- `supabase.from('qa_questions')` + `qa_answers` — integrated into tab
- Progress saving interval change: 10s → 30s

**Existing code reused:**
- `/learn/[courseId]/page.tsx` — entire structure (sections, active lesson, video, tabs)
- `VideoPlayer.tsx` — YouTube + HTML5 playback
- Lesson navigation logic
- Tab content structure

**Existing code refactored:**
- `/learn/[courseId]/page.tsx` — add 5-tab system, integrate Q&A/rating, add notes/bookmarks tabs, add completion dialog
- `VideoPlayer.tsx` — add speed control, fullscreen button

**New work required:**
- CompletionAnimation component
- CourseCompletedDialog component
- Notes tab UI
- Bookmarks tab UI
- Q&A tab (adapted from `/qa` page logic)
- Rating tab (adapted from ReviewsSection)
- Quiz tab within player
- Fullscreen video mode
- Speed control UI
- Notes/bookmarks Supabase integration

**Risks:**
- **High:** This is the most complex screen refactor. Many interdependent state variables.
- **Medium:** Q&A and Rating tabs need to work within the player's tab context while pulling data from existing Supabase tables.
- **Low:** Notes and bookmarks are new features but simple CRUD.

**Estimated complexity:** Very High

**QA checklist:**
- [ ] 5-tab system renders: Lectures, More, Q&A, Quizzes, Rating
- [ ] Tab content loads correctly for each tab
- [ ] Video: speed control works (0.5x–2x)
- [ ] Video: fullscreen works, Escape exits
- [ ] Notes: add, list, delete, timestamp shown
- [ ] Bookmarks: add, list, "Go to Lesson" navigation
- [ ] Q&A: ask question, view answers, instructor highlighting
- [ ] Rating: distribution chart, write review, review cards
- [ ] Completion dialog: shows on all lessons completed
- [ ] Bottom bar: Next Lesson + Resources buttons work
- [ ] Progress saves every 30s
- [ ] Auto-complete at 95%

**Acceptance criteria:**
- Course player has 5-tab system matching mobile
- Notes, bookmarks, Q&A, rating all work
- Completion flow shows dialog
- Video has speed + fullscreen controls

**Definition of Done:** Course player matches mobile's tab structure and all tab content works.

---

### Phase 10: Cart + Wishlist + My Learning + History

**Objective:** Align these secondary pages to match mobile's layout and features.

**Why this phase comes now:** These are enrolled-user pages that depend on course card components and design tokens. They can be done in parallel by different developers after the component library is ready.

**Features included:**

**10a. Cart (`/cart`):**
- Restyle cart item cards: add instructor name + rating row to each card
- Collapsible coupon section (animated cross-fade, applied state with success message + close)
- Match summary card styling (dual shadows, price formatting)
- Add shimmer loading skeleton
- Better empty state (animated, with illustration)
- Error shake animation on failed removal

**10b. Wishlist (`/wishlist`):**
- Expand from minified code to readable
- Add filter tabs (All, Price Drops, Enrolled)
- Add total value bar at bottom + "Add All to Cart" button
- Match glass card styling with favorite button
- Add time-ago footer with action button states (Add to Cart / In Cart / Go to Learning / Purchased)

**10c. My Learning (`/my-learning`):**
- Add filter tabs (In Progress / Completed / All) with counts
- Add dedicated Continue Learning card at top (progress bar, resume button, status badges)
- Add recommended courses section
- Add pagination (20-item page size, load more at scroll end)
- Improve course cards: add status badges (inactive/completed/expiry), matching mobile's EnrolledCourseCard

**10d. History (`/history`):**
- Expand from minified code
- Switch to per-lesson history model (LessonHistoryService equivalent)
- Each card: lesson thumbnail, lesson title, course title, time ago
- Back button matching mobile
- Navigate to course player on tap

**Screens affected:** `/cart`, `/wishlist`, `/my-learning`, `/history`

**Components affected:** AppCard, AppButton, ShimmerEffect, PriceTag, RatingStars, FilterChips

**APIs affected:**
- `supabase.from('lesson_watch_history')` — new query for per-lesson history
- My Learning pagination
- Existing cart/wishlist queries (reuse)

**Existing code reused:**
- `/cart/page.tsx` — item list, coupon logic, summary calculation, checkout flow
- `/wishlist/page.tsx` — course fetch, remove logic
- `/my-learning/page.tsx` — enrollment fetch, progress calculation
- Cart/wishlist AppContext methods

**Existing code refactored:**
- All four pages — restyle with shared components, add missing sections

**New work required:**
- Continue Learning card component
- Wishlist total value bar
- "Add All to Cart" bulk action
- Per-lesson history query
- My Learning filter tabs + recommended section

**Risks:** Low–Medium (refactoring existing working pages)

**Estimated complexity:** Medium

**QA checklist:**
- [ ] Cart: instructor + rating shown on item cards
- [ ] Cart: collapsible coupon section works with animation
- [ ] Cart: shimmer skeleton on loading
- [ ] Wishlist: filter tabs work (All, Price Drops, Enrolled)
- [ ] Wishlist: total value bar + "Add All to Cart" render
- [ ] My Learning: filter tabs with counts
- [ ] My Learning: continue learning card at top
- [ ] My Learning: recommended section
- [ ] My Learning: pagination loads more on scroll
- [ ] History: per-lesson cards with lesson title + course title + time ago

**Acceptance criteria:**
- All four pages match mobile layouts
- All missing features added

**Definition of Done:** Cart, Wishlist, My Learning, and History match mobile.

---

### Phase 11: Notifications + Payments

**Objective:** Enhance notifications and payments pages to match mobile.

**Why this phase comes now:** These are secondary engagement/account pages with lower traffic than core content pages.

**Features included:**

**11a. Notifications (`/notifications`):**
- Expand from minified code
- Add notification type-specific icons and colors (10+ types: instructorMessage→message, courseUpdate→school, quizResult→quiz, certificateIssued→workspace_premium, etc.)
- Add date grouping (Today, Yesterday, date headers)
- Add "Mark All as Read" button in toolbar
- Add animated entrance (SlideFadeIn stagger)
- Add swipe-to-delete
- Improve card styling: unread bg tint, icon container 44x44 with type color

**11b. Payments (`/payments`):**
- Add 5-tab filtering: All, Paid, Pending, Refunded, Cancelled with counts in tab labels
- Match mobile's PaymentCard styling (status chips, order number row, courses list, total amount)
- Add payment detail bottom sheet (DraggableScrollableSheet equivalent)
- Add pull-to-refresh

**Screens affected:** `/notifications`, `/payments`

**Components affected:** FilterChips, AppCard, AppButton, BottomSheet (new)

**APIs affected:**
- `supabase.from('notifications')` — add type mapping
- `supabase.from('parent_enrollments')` — existing, add status filtering

**Existing code reused:** Both pages' data fetching logic

**Existing code refactored:**
- `/notifications/page.tsx` — expand, add type icons, grouping, animations
- `/payments/page.tsx` — add tabs, detail sheet

**New work required:**
- Notification type icon mapping
- Date grouping logic
- Swipe-to-delete interaction
- Payment detail bottom sheet
- Tab filtering with counts

**Risks:** Low

**Estimated complexity:** Medium

**QA checklist:**
- [ ] Notifications show type-specific icons
- [ ] Notifications grouped by Today/Yesterday/date
- [ ] Mark-all-as-read works
- [ ] Swipe-to-delete works
- [ ] Payments: 5-tab filter with counts
- [ ] Payment detail bottom sheet with breakdown opens on tap

**Acceptance criteria:** Both pages match mobile's layout and features.

**Definition of Done:** Notifications and Payments match mobile.

---

### Phase 12: Forums + Chat + Q&A

**Objective:** Enhance forums, direct chat, and Q&A pages to match mobile's rich feature set.

**Why this phase comes now:** Community features are complex and depend on responsive dialog, reaction picker, message bubble components. These were built in Phase 2.

**Features included:**

**12a. Forums list (`/forums`):**
- Add filter chips (All / Groups / Private) with animated selection
- Restyle conversation cards: 64x64 avatar, type badge (Group=success, Private=warning), last message preview, time
- Add shimmer loading
- Add instructor management link (if instructor)

**12b. Forum chat (`/forums/[id]`):**
- Add message reactions (6 emoji picker on tap: 👍❤️😂😮😢🙏)
- Add swipe-to-reply gesture
- Add reply-to preview bar (with vertical primary bar)
- Add message options on long press (copy, reply, delete if admin/own)
- Add search bar for messages
- Differentiate own vs others' message bubble colors
- Show sender name + avatar for others' messages

**12c. Direct chat (`/chat`):**
- Add read receipts (✓ single sent, ✓✓ blue read)
- Add message reactions (🔥 replaces 🙏)
- Add swipe-to-reply
- Differentiate from forum chat: own message bubbles use primary alpha bg

**12d. Q&A (`/qa`):**
- Add validation rules matching mobile (title min 10 chars, content min 20 chars)
- Match instructor answer highlighting style (primary bg + "Instructor" badge)
- Add question count display
- Integrate question asking into course player (Phase 9 already covers this)

**Screens affected:** `/forums`, `/forums/[id]`, `/chat`, `/qa`

**Components affected:** ReactionPicker, MessageBubble, SwipeToReply, ResponsiveDialog

**APIs affected:**
- `supabase.from('message_reactions')` — new CRUD
- `supabase.from('direct_message_reactions')` — new CRUD
- `supabase.from('messages')` — add read status updates
- Existing forum/chat message queries (reuse)

**Existing code reused:**
- All four pages' data fetching + real-time subscription logic
- Message sending/receiving logic
- Chat UI structure

**Existing code refactored:**
- Message bubble CSS — own/others differentiation, reactions display
- Chat input — add reply preview above
- Forum list — add filter chips

**New work required:**
- ReactionPicker component
- Swipe-to-reply gesture handler
- Read receipt rendering
- Reply preview bar
- Message long-press options sheet
- Read status mark API call

**Risks:**
- **Medium:** Swipe-to-reply needs careful gesture handling to not interfere with scrolling
- **Low:** Reactions are simple CRUD + optimistic updates

**Estimated complexity:** High

**QA checklist:**
- [ ] Forums: filter chips work (All/Groups/Private)
- [ ] Forums: conversation cards match mobile styling
- [ ] Chat: tap message → reaction picker with 6 emojis
- [ ] Chat: swipe right → reply gesture activates
- [ ] Chat: reply preview shown above input
- [ ] Chat: long press → options (copy/reply/delete)
- [ ] Chat: own vs others bubbles differentiated
- [ ] Direct chat: read receipts (✓/✓✓) render
- [ ] Direct chat: reactions use 🔥 instead of 🙏
- [ ] Q&A: validation enforces min 10/20 chars
- [ ] Q&A: instructor answers highlighted with badge

**Acceptance criteria:**
- All chat/forum pages match mobile's features
- Reactions, reply-to, read receipts all work

**Definition of Done:** Forums, chat, and Q&A match mobile's interaction patterns.

---

### Phase 13: Checkout + Payment Success Adjustments

**Objective:** Align the checkout and payment success flows with mobile. This requires a **product decision** on whether to keep Paymob or switch to manual payment.

**Why this phase comes now:** Payment is business-critical. It must be handled after all other student-facing pages are correct. The Paymob gateway already works and is used in production — we must not break it. Instead, we add manual payment as an additional option matching mobile.

**Features included:**
- Add manual payment option alongside Paymob (hybrid approach)
- When user selects manual: hide card/wallet fields, show info box explaining manual process
- **Payment Success page:** Add order ID display (with copy button), add WhatsApp contact button (with phone number lookup), add short order ID formatting
- Match mobile's layout: 112x112 success circle, title, subtitle, order ID tile, WhatsApp button, back to home
- Add manual payment info box (`info@0.1` bg, `info@0.3` border, info icon + description)

**Screens affected:** `/checkout`, `/checkout/success`

**Components affected:** AppCard, AppButton, AppTextField

**APIs affected:**
- If manual payment: `supabase.rpc('create_enrollment')` with manual method
- WhatsApp phone lookup: query instructor profile from course

**Existing code reused:**
- `/checkout/page.tsx` — Paymob flow (keep as-is)
- `/checkout/success/page.tsx` — polling logic
- `/api/paymob/route.ts` — keep for Paymob payments

**Existing code refactored:**
- `/checkout/page.tsx` — add payment method selector (manual vs card/wallet)
- `/checkout/success/page.tsx` — add order ID display, WhatsApp button

**New work required:**
- Manual payment flow (submit request → wait for approval)
- WhatsApp contact button with instructor phone lookup
- Order ID copy-to-clipboard

**Risks:**
- **High:** Payment changes affect revenue. Must be thoroughly tested. Keep Paymob working.
- **Medium:** Manual payment requires different order creation flow.

**Estimated complexity:** High (financial-critical)

**QA checklist:**
- [ ] Paymob payment flow still works (regression test)
- [ ] Manual payment option available in UI
- [ ] Manual payment submits and creates enrollment
- [ ] Payment success: order ID shows with copy button
- [ ] Payment success: WhatsApp button opens WhatsApp with correct number
- [ ] Both payment methods work end-to-end

**Acceptance criteria:**
- Both Paymob and manual payment paths work
- Payment success page matches mobile layout

**Definition of Done:** Checkout and payment success match mobile; both payment methods functional.

---

### Phase 14: Instructor Dashboard

**Objective:** Build the entire instructor dashboard — 14 tabs with course management, student management, quiz management, earnings, coupons, Q&A, reviews, categories, and banners.

**Why this phase comes now:** This is the largest net-new feature. It has zero existing code to refactor. It's a separate user role (instructor/admin) and can be developed as a nearly standalone app section. Starting it after the component library means it can use all shared components from day one.

**Features included (14 tabs):**

| Tab | Screen/Content | Key Features |
|-----|----------------|--------------|
| 0 | Dashboard Home | Stats grid (6 cards), date range selector, earnings + enrollment charts |
| 1 | My Courses | Course list, create/edit course (5-step editor) |
| 2 | Students | Student list, search, details view |
| 3 | Forums | Reuse ForumsListScreen + management controls |
| 4 | Enrollments | Per-course enrollment list |
| 5 | Purchase Requests | Manual approval workflow with day options |
| 6 | Earnings | Summary cards, period filters, transaction list |
| 7 | Coupons | Coupon list, create/edit coupon |
| 8 | Quizzes | Quiz list, create/edit quiz, question management, preview |
| 9 | Q&A | Questions list, answer management |
| 10 | Reviews | Reviews list, response management |
| 11 | Categories | Category list, create/edit with icon selector |
| 12 | Banners | Banner list, create/edit with image/date/link |
| 13 | Settings | Instructor-specific settings |

**Sub-screens:**
- Course editor (5 steps: Basic Info, Curriculum, Pricing, Attachments, Settings)
- Course edit step screen
- Student details, progress, enrollments
- Send message screen
- Quiz editor, create quiz, question editor
- Quiz attempts, quiz response details
- Coupon editor
- Earnings history
- Category editor
- Banner editor

**Screens affected:** New `/instructor/*` route group (14+ pages)

**Components affected:** All shared components from Phase 2, plus new: `DashboardScaffold`, `StatsGrid`, `DashboardChart`, `CourseEditorStepper`, `QuizEditorForm`, `CouponEditorForm`

**APIs affected:**
- Extensive: `instructor_stats`, `instructor_courses`, `instructor_students`, `instructor_enrollments`, `instructor_earnings`, `instructor_qa`, `instructor_reviews`, `coupons`, `categories`, `banners`, `quiz_attempts` — many new Supabase queries and RPC calls
- Course CRUD (sections, lessons, attachments)
- Image upload for courses/banners
- Quiz/question CRUD

**Existing code reused:**
- AppContext (user role detection for access control)
- Supabase client
- Shared UI components
- Forum management logic from mobile reference

**Existing code refactored:** None (net-new)

**New work required:** ~15 new page files, ~10 new sub-component files, ~5 new API integration modules

**Risks:**
- **High:** Largest single feature. Very high scope.
- **Medium:** Complex form editors (course 5-step, quiz question editor)
- **Low:** Data comes from existing Supabase tables

**Estimated complexity:** Very High

**QA checklist:**
- [ ] Dashboard shows stats + charts matching mobile
- [ ] Course editor 5 steps all work (create + edit)
- [ ] Curriculum section: add/reorder/delete sections + lessons
- [ ] Pricing: subscription options, flash sale, badge
- [ ] Student management: view details, progress, enrollments, send message
- [ ] Quiz management: create/edit, question management, preview
- [ ] Coupon CRUD works
- [ ] Earnings history with period filters
- [ ] Category + Banner CRUD with image upload
- [ ] Purchase requests: approve/reject with day selection
- [ ] Q&A + Reviews tabs render and function
- [ ] Access control: only instructors/admins can access

**Acceptance criteria:**
- All 14 tabs render with mobile-matching layouts
- Core instructor workflows work end-to-end (create course, manage students, view earnings)
- Access control prevents non-instructors

**Definition of Done:** Instructor dashboard matches mobile's 14-tab structure and all key workflows function.

---

### Phase 15: Animations + State Patterns

**Objective:** Apply mobile-matching animations, loading skeletons, empty states, error states, and toast patterns across ALL existing screens. This is a cross-cutting polish pass.

**Why this phase comes now:** After all screens are functionally correct, we apply the polish layer. Doing this earlier would conflict with ongoing refactors. Doing it now means it's applied once to stable screens.

**Features included:**

**Animations (React/CSS equivalents of mobile's Flutter animations):**
- `SlideFadeIn` — opacity 0→1 + translateY 20→0, staggered with configurable delay
- `FadeIn` — opacity 0→1 with delay
- `ScaleIn` — scale 0.8→1 + opacity 0→1, easeOutBack curve
- `PulseAnimation` — scale 1.0→1.1, 1000ms repeat reverse
- `BounceAnimation` — scale sequence 1.0→1.3→0.9→1.0
- `ErrorShake` — horizontal shake, 3 iterations, 500ms
- `AnimatedCard` — scale 1.0→0.98 on press, elevation change
- `CompletionAnimation` — scale + checkmark draw (600ms)

**Loading States (shimmer skeletons):**
- Home: multi-section skeleton with card placeholders
- Course details: hero + stats + text line skeletons
- Course player: video + sidebar skeletons
- My Learning: course card skeletons
- Cart: item + summary skeletons
- Notifications: list item skeletons
- Generic: `SkeletonListItem`, `SkeletonCourseCard`, `SkeletonText` components

**Empty States (all 17 mobile types):**
- courses, cart, wishlist, search, notifications, certificates, myLearning, instructors, reviews, qa, generic, lessons, notes, bookmarks, attachments, announcements, quizzes, forum

**Error States (5 types × 3 densities):**
- network, server, notFound, unauthorized, generic
- fullPage, section, compact display modes

**Toast Notifications:**
- success (green bg), error (red bg), warning (orange bg), info (blue bg)
- Floating, auto-dismiss 3s, consistent shape

**Screens affected:** ALL — this is a cross-cutting pass

**Components affected:** ShimmerEffect (enhance), EmptyState (add all types), ErrorState (add all types), LoadingState (add all densities)

**APIs affected:** None

**Existing code reused:**
- GSAP hooks from `src/lib/animations.ts` (extend)
- `.fade-in` CSS animation from globals.css (replace with mobile-matching timing)
- `PageTransition.tsx` component (extend)

**Existing code refactored:**
- Every page's "Loading..." text → ShimmerEffect
- Every page's simple empty text → EmptyState component
- Every page's error handling → ErrorState component
- Replace inline `alert()` calls with Toast

**New work required:**
- CSS keyframe animations matching mobile's curves/durations
- React hooks: `useSlideFadeIn`, `useScaleIn`
- Skeleton variants for each page type
- Empty state icon/illustration variants

**Risks:**
- **Low:** These are additive improvements. They don't break existing functionality.
- **Medium:** Performance of many simultaneous shimmer animations needs testing.

**Estimated complexity:** High (breadth across all pages)

**QA checklist:**
- [ ] Every page shows shimmer skeleton while loading
- [ ] Every empty state matches mobile's type (cart→cart illustration, etc.)
- [ ] Every error state matches mobile's type and density
- [ ] SlideFadeIn animations stagger on list entries
- [ ] ScaleIn animation on action buttons
- [ ] PulseAnimation on quiz timer when <60s
- [ ] ErrorShake on cart removal failure
- [ ] Toast shows on all success/error operations
- [ ] Smooth 60fps with multiple shimmer animations active

**Acceptance criteria:**
- Loading, empty, error, and success states match mobile on every screen
- Animations match mobile's timing, curves, and patterns

**Definition of Done:** All screens have matching loading/empty/error/success states with correct animations.

---

### Phase 16: Offline + Connectivity + Final Polish

**Objective:** Add offline detection, responsive bottom navigation refinement, and address remaining minor differences.

**Why this phase comes now:** These are low-priority features that enhance robustness. They should be added after all core functionality is parity-matched.

**Features included:**
- Online/offline detection hook (`useOnlineStatus`)
- Offline indicator banner at top (animated slide-in, warning color, retry button)
- Bottom navigation refinement: glass backdrop blur, pill selector animation timing
- Responsive dialog width adjustment (mobile/tablet/desktop breakpoints)
- Course player: mini-player overlay when navigating away
- Remove `dangerouslySetInnerHTML` from course descriptions (sanitize or render as plain text)
- Fix `supabaseClient.ts` — remove hardcoded fallback URL + key
- Add `noopener noreferrer` to all external links
- Add proper HTML `lang` and `dir` attribute toggling
- Verify all ARIA labels on interactive elements

**Screens affected:** ALL (offline banner is app-level)

**Components affected:** OfflineIndicator (new), MiniPlayerOverlay (new)

**APIs affected:** None

**Existing code reused:** AppContext connection detection

**Existing code refactored:**
- `supabaseClient.ts` — remove hardcoded credentials
- `/courses/[id]/page.tsx` — replace dangerouslySetInnerHTML
- `layout.tsx` — add offline indicator

**New work required:**
- Online status hook
- Offline banner component
- Mini player overlay (track video state globally)
- HTML sanitization for course descriptions

**Risks:** Low

**Estimated complexity:** Low–Medium

**QA checklist:**
- [ ] Offline banner appears when connection lost
- [ ] Offline banner disappears when connection restored
- [ ] Retry button on offline banner triggers reconnect
- [ ] Bottom nav glass effect renders on mobile
- [ ] No hardcoded Supabase credentials in source
- [ ] No dangerouslySetInnerHTML without sanitization
- [ ] All interactive elements have ARIA labels
- [ ] Mini player overlay shows when leaving course player during playback

**Acceptance criteria:** All polish features work; security issues resolved.

**Definition of Done:** Web app handles offline gracefully; no security concerns remain.

---

## Dependency Graph Between Phases

```
Phase 0 (Tokens)
    ↓
Phase 1 (Icons)
    ↓
Phase 2 (Components)
    ↓
Phase 3 (Utilities)
    ↓
    ├─→ Phase 4 (Auth)
    ├─→ Phase 5 (Navigation)
    │      ↓
    │      ├─→ Phase 6 (Home)  ← also depends on Phase 2 components
    │      ├─→ Phase 7 (Profile/Settings)
    │      ├─→ Phase 8 (Course Details/Search)
    │      ├─→ Phase 9 (Course Player)  ← also depends on Phase 2+3
    │      ├─→ Phase 10 (Cart/Wishlist/MyLearning/History)
    │      ├─→ Phase 11 (Notifications/Payments)
    │      ├─→ Phase 12 (Forums/Chat/Q&A)
    │      └─→ Phase 13 (Checkout/Payment)
    │
    └─→ Phase 14 (Instructor Dashboard)  ← depends on Phase 2, parallel with Phases 5-13
           ↓
Phase 15 (Animations/States)  ← depends on all screens being stable
    ↓
Phase 16 (Offline/Polish)  ← depends on Phase 15
```

**Parallelization opportunity:** Phases 6–13 can be worked on by different developers simultaneously after Phases 0–5 are complete. Phase 14 (Instructor Dashboard) is a separate workstream that can start after Phase 2 and proceed in parallel with Phases 4–13.

---

## Risk Analysis

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Lime accent removal breaks many UI elements | High | High | Phase 0 must simultaneously replace ALL `var(--accent)` references with `var(--primary)` |
| Dark mode color change makes content invisible | Medium | High | Test every single page in dark mode immediately after Phase 0 |
| OTP password reset requires backend template change | Medium | High | Coordinate with backend team; test OTP flow in staging before deploying |
| Paymob checkout breaks during manual payment integration | Medium | Critical | Keep Paymob as default; manual payment is an additional option, not replacement |
| Instructor dashboard scope creep | High | Medium | Strict 14-tab scope; defer non-essential sub-features to post-parity release |
| GSAP + Tailwind conflicts | Low | Medium | Keep GSAP for scroll-triggered animations; use CSS for micro-interactions |
| Multi-step registration increases drop-off | Low | Low | Matches mobile; this is a product parity decision, not a risk |
| Image upload in edit profile fails on large files | Medium | Low | Add client-side compression (matching mobile's `flutter_image_compress`) |
| CSS module refactoring causes regressions | Medium | Medium | Phase 0 tokens change should be a single commit; visual test all pages before proceeding |

---

## Regression Prevention Strategy

1. **Visual checkpoint after each phase:** Before moving to the next phase, run the complete QA checklist for the current phase AND spot-check 3 previously completed phases.

2. **Design token lock:** After Phase 0, lock `globals.css` CSS custom properties. Any token change requires explicit review.

3. **Component library versioning:** After Phase 2, treat `src/components/ui/` as a stable API. Breaking changes require team review.

4. **Payment protection:** Never modify `/api/paymob/route.ts` or the Paymob checkout flow without a full payment regression test.

5. **Auth flow protection:** After Phase 4, all auth changes require testing: login, register (4 stages), email verification, OTP reset, interests, and session persistence.

6. **E2E smoke test suite:** After Phase 4, create a minimal E2E test for every completed flow:
   - Auth: login → home
   - Browse: home → course details → enroll/add-to-cart
   - Learn: my-learning → course player → complete lesson
   - Cart: add → checkout → success
   - Profile: view → edit → save

7. **Build verification:** Run `npm run build` before every merge. Type errors from component API changes must fail the build.

8. **Dark/light mode toggle test:** After every phase, toggle theme on every modified page and verify no invisible text or broken layouts.

---

## Final QA Strategy

### Per-Phase QA (during development)
- Each phase has its own QA checklist (see above)
- Developer self-tests against checklist before marking phase complete
- Peer review of component API before merging

### Cross-Phase QA (after each phase)
- Verify previously completed phases still work
- Run dark/light + RTL/LTR on all modified pages

### Final Comprehensive QA (after Phase 16)

**Screen-by-screen comparison matrix:**

| # | Screen | Light | Dark | RTL | Loading | Empty | Error | Success |
|---|--------|-------|------|-----|---------|-------|-------|---------|
| 1 | /login | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 2 | /forgot-password | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 3 | /reset-password | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 4 | /interests | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 5 | / (home guest) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 6 | / (home logged-in) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 7 | /profile | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 8 | /edit-profile | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 9 | /settings | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 10 | /search | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 11 | /categories | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 12 | /courses/[id] | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 13 | /learn/[courseId] | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 14 | /quiz/[id] | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 15 | /my-learning | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 16 | /cart | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 17 | /checkout | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 18 | /checkout/success | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 19 | /payments | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 20 | /wishlist | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 21 | /history | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 22 | /notifications | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 23 | /forums | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 24 | /forums/[id] | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 25 | /chat | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 26 | /qa | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 27 | /report | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 28 | /parent-portal | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |
| 29 | /privacy | ☐ | ☐ | ☐ | ☐ | N/A | N/A | N/A |
| 30 | /terms | ☐ | ☐ | ☐ | ☐ | N/A | N/A | N/A |
| 31–44 | /instructor/* (14 tabs) | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ | ☐ |

**Mobile side-by-side comparison:**
- For each screen, open mobile app and web app side-by-side
- Compare every visual element: colors, fonts, sizes, spacing, icons, borders, shadows
- Compare every interaction: button press, navigation, form validation, scroll behavior
- Compare every state: loading, empty, error, success
- Document any remaining differences

**Accessibility audit:**
- All interactive elements keyboard-accessible
- All images have alt text
- All form fields have labels
- Color contrast meets WCAG 2.1 AA (match mobile's accessible contrast ratios)
- Focus order is logical (RTL-aware)
- Screen reader compatible

**Cross-browser testing:**
- Chrome (latest)
- Firefox (latest)
- Safari (latest)
- Edge (latest)
- Mobile Safari (iOS)
- Chrome Mobile (Android)

**Performance verification:**
- First Contentful Paint < 2s
- No layout shifts from font loading (Almarai preloaded)
- Shimmer animations at 60fps
- No memory leaks from GSAP ScrollTrigger (cleanup verified)

---

## Final Acceptance Criteria

The Web Platform is considered at 100% parity when:

1. ✅ Every screen that exists in Mobile exists in Web
2. ✅ No screen exists in Web that has features not in Mobile (except Paymob as additional payment option)
3. ✅ All colors match AppColors tokens in both light and dark modes
4. ✅ Almarai font is the only font family used
5. ✅ Material Icons are used throughout (matching mobile's icon choices)
6. ✅ All spacing matches mobile's 8px grid system
7. ✅ All border-radius values match mobile's AppRadius scale
8. ✅ All shadows are neutral (no purple tints)
9. ✅ No lime/plasma accent colors exist
10. ✅ Dark mode uses blue primary palette (#2563EB / #93C5FD)
11. ✅ Every button, input, card, dialog matches mobile's component specs
12. ✅ Every form validation message matches mobile's Arabic/English messages
13. ✅ Every loading state shows shimmer skeleton matching mobile
14. ✅ Every empty state matches mobile's animated type-specific illustrations
15. ✅ Every error state matches mobile's type/density variants
16. ✅ Every animation timing/curve matches mobile
17. ✅ Auth flow matches mobile (4-stage register, OTP reset, email verification)
18. ✅ Navigation matches mobile (4-tab glass bottom nav)
19. ✅ Home screen matches mobile (banner carousel, categories, flash sale, sections)
20. ✅ Course player matches mobile (5 tabs, notes, bookmarks, completion dialog)
21. ✅ Instructor dashboard has all 14 tabs matching mobile
22. ✅ Chat/forum features match mobile (reactions, read receipts, swipe-to-reply)
23. ✅ Profile/edit-profile/settings match mobile
24. ✅ Cart/wishlist/payment-history match mobile
25. ✅ All API-driven states behave identically
26. ✅ RTL (Arabic) and LTR (English) rendering is correct on all screens
