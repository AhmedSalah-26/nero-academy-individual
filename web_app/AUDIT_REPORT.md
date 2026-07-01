# Mobile ↔ Web Parity Audit Report

**Date:** 2026-06-30  
**Mobile App:** Flutter (Almarai font, AppColors design system, BLoC state management)  
**Web App:** Next.js 16 (Readex Pro / Plus Jakarta Sans / Changa fonts, CSS custom properties, Tailwind, Context API)  
**Mobile Source of Truth Version:** 1.0.1+2  

---

## Parity Differences Table

| # | Screen | Section | Component | Mobile | Web | Difference | Required Fix | Priority | Notes |
|---|--------|---------|-----------|--------|-----|------------|--------------|----------|-------|
| 1 | Global | Design System | Font Family | Almarai (300/400/500/600/700/800/900) | Readex Pro (Arabic), Plus Jakarta Sans (English), Changa (display) | Completely different font families | Replace web fonts with Almarai via Google Fonts CDN or self-hosted; update `--font-arabic`, `--font-english`, `--font-display` | Critical | Font is the #1 brand identifier |
| 2 | Global | Design System | Primary Color (Dark) | `#2563EB` / `#93C5FD` (primaryOnDark) | `#9b4dff` (dark mode primary) | Web dark mode uses purple instead of blue | Change `--primary` dark to `#2563EB`, dark accent to `#93C5FD` | Critical | |
| 3 | Global | Design System | Background Light | `#EFF6FF` (blue-tinted) | `#F7F7FB` (grey-tinted) | Different light background | Change to `#EFF6FF` | High | |
| 4 | Global | Design System | Background Dark | `#07111F` (deep navy) | `#07040F` (deep purple-black) | Different dark background | Change to `#07111F` | High | |
| 5 | Global | Design System | Surface Dark | `#0F172A` | `rgba(22,15,37,0.86)` | Different surface color & opacity | Use solid `#0F172A` | High | |
| 6 | Global | Design System | Card Dark | `#172033` | `rgba(27,18,46,0.9)` | Different card surface | Use solid `#172033` | High | |
| 7 | Global | Design System | Text Muted Light | `#4B5563` | `#625A70` (purple-grey) | Different muted text color | Change to `#4B5563` | High | |
| 8 | Global | Design System | Text Muted Dark | `#D1D5DB` | `#c9c1dc` (purple-grey) | Different muted text color | Change to `#D1D5DB` | High | |
| 9 | Global | Design System | Border Light | `#E5E7EB` | `rgba(64,44,92,0.14)` (purple tint) | Different border color | Use `#E5E7EB` | High | |
| 10 | Global | Design System | Border Dark | `#374151` | `rgba(178,133,255,0.2)` (purple) | Different border color | Use `#374151` | High | |
| 11 | Global | Design System | Accent Color | None (uses primary blue) | `#DDFB55` (lime/chartreuse) used extensively | Web introduces lime accent color not in mobile | Remove lime accent; use primary `#2563EB` as accent | Critical | Lime changes entire visual identity |
| 12 | Global | Design System | Plasma Color | None | `#B87CFF` used in UI | Non-existent in mobile design | Remove entirely | High | |
| 13 | Global | Design System | Rating Color | `#B47D00` (accessible gold) | `#E59819` | Different rating star color | Change to `#B47D00` | Medium | |
| 14 | Global | Design System | Border Radius | xs=4, sm=8, md=12, lg=16, xl=20, xxl=24, full=9999 | sm=10, md=16, lg=24, xl=32 | Web radius values don't match mobile scale | Align all border-radius tokens to mobile values | High | |
| 15 | Global | Design System | Shadows | black@0.04/0.06/0.09/0.1 alpha with specific offsets | Purple-tinted shadows throughout | Web uses purple-tinted shadows; mobile uses neutral | Replace purple shadow tints with neutral black shadows | High | |
| 16 | Global | Design System | Typography Scale | displayLarge=32, displayMedium=28, displaySmall=24, headlineLarge=22, headlineMedium=20, headlineSmall=18, titleLarge=18, titleMedium=16, titleSmall=14, bodyLarge=16, bodyMedium=14, bodySmall=12, labelLarge=14, labelMedium=12, labelSmall=11, buttonLarge=16, buttonMedium=14, buttonSmall=12 | No defined scale; uses clamp() with display fonts up to 5.55rem | No consistent type scale on web | Implement matching type scale with Almarai font | Critical | |
| 17 | Global | Glass Effect | GlassSearchBar/GlassIconButton: blur sigma 20, border 1.5px white/15% or primary/28% | `.glass` class: blur 16px, `var(--glass-border)` | Slightly different blur levels and border styling | Align blur sigma and border values | Medium | |
| 18 | Global | Icons | Material Icons (Flutter's Icons.* set) | Lucide React icons | Completely different icon library | Replace Lucide with Material Icons or use a React Material Icons library | High | |
| 19 | Global | Spacing System | 8px grid: xs=4, sm=8, md=16, lg=24, xl=32, xxl=40, xxxl=48 | No defined spacing system | No consistent spacing tokens | Define and use mobile's spacing scale | High | |
| 20 | Global | Dark Mode Toggle | ThemeCubit with warm brown/terracotta palette (ThemeCubit) OR AppColors blue palette | CSS `data-theme` attribute with purple dark palette | Web dark mode is purple-themed; mobile has two competing themes (AppColors blue vs ThemeCubit brown) | Resolve: mobile AppColors blue palette is the used one; web must match it | Critical | |
| 21 | Splash | Entire Screen | Animated splash with logo, brand name, slogan, loading spinner, decorative circles, fade+scale animation | No splash screen | Missing splash screen | Add splash screen or landing redirect matching mobile | Low | Desktop rarely needs splash |
| 22 | Login | Brand Header | "شهاب Tech" / "Shahab Tech" with gradient ShaderMask, size 22, w800 | No brand header on login | Missing brand identity on login | Add gradient brand name at top of login card | Critical | |
| 23 | Login | Tab Switching | AuthTabBar with sliding pill indicator (AnimatedAlign, 300ms, easeOutBack) | Text toggle "Login / Sign Up" with underline | Different tab switcher UI | Implement sliding pill tab bar matching mobile | High | |
| 24 | Login | Form Fields | AuthTextField: label 13px w500, input 14px, prefix icon 20px, border radius 12, cardDark/white fill | Standard HTML inputs: border-radius 10px, padding 14px 16px, surface bg | Different field styling | Restyle to match AuthTextField specs | High | |
| 25 | Login | Multi-Stage Register | 4-stage wizard: Basic Info → Contact (email+phone) → Password → Profile Photo | Single-page form: Name, Phone, Email, Password all at once | Web doesn't use multi-step registration | Implement 4-stage registration flow | High | |
| 26 | Login | Register Phone | PhoneInputField with country code selector (+20 default), country_picker package | Simple text input for phone | No country code selector | Add country code selector with +20 default | High | |
| 27 | Login | Social Login | Google only (Apple/Facebook code exists but showApple: false, showFacebook: false) | Google, Apple, Facebook all shown | Web shows non-functional Apple/Facebook login | Hide Apple/Facebook; show only Google matching mobile | Critical | |
| 28 | Login | Awaiting Verification | Inline verification view: card with mail icon, email display, resend button | No email verification flow at all | Missing email verification | Add email verification flow with resend | Critical | |
| 29 | Login | Validation Messages | Arabic error messages: email required/invalid, password min 8, confirm mismatch, etc. | HTML5 browser validation only | No custom validation messages | Add custom Arabic/English validation matching mobile | High | |
| 30 | Login | Register: Email Availability | Checks email availability via Supabase profiles query in real-time | No email availability check | Missing feature | Add real-time email availability check | Medium | |
| 31 | Login | Instructor Registration | Disabled: throws AuthException "instructor_signup_disabled" | Role selector allows Instructor selection on sign-up | Web allows instructor sign-up that mobile blocks | Disable instructor sign-up; match mobile restriction | Critical | |
| 32 | Login | Google Auth | google_sign_in package with Supabase signInWithIdToken | Supabase signInWithOAuth (redirect-based) | Different auth flow (same Supabase backend) | Acceptable platform difference | Low | |
| 33 | Forgot Password | OTP-based Reset | 2-phase: enter email → receive OTP → enter OTP + new password + confirm | Magic link: enter email → click link in email → enter new password on /reset-password | Completely different password reset mechanism | Implement OTP-based reset matching mobile | Critical | |
| 34 | Forgot Password | UI Layout | Icon (80x80 circle) + title + subtitle + field + button + back link | Simple card with email field and "Send Link" button | Missing visual elements | Add header icon, matching layout | High | |
| 35 | Reset Password | Entire Screen | Deep linkmagic link reset: reads URL error params, shows form/done states, inline _MessageBox | /reset-password: simple 2-field form, no error reading from URL, no success animation | Missing URL error reading, missing success state | Add error parsing from URL, add success completion state | High | |
| 36 | Interests | Minimum Selection | Minimum 3 interests required; button disabled otherwise | No minimum; save enabled with any selection | No minimum enforced | Add minimum 3 selection requirement | High | |
| 37 | Interests | Category Icons | Per-category Material icons (code, palette, business_center, etc.) | No category icons shown | Missing icons | Add category-specific icons | Medium | |
| 38 | Interests | Selection UI | AnimatedContainer chips with shadow, check icon, borderRadius 20 | Selectable div chips with primary-glow bg | Different chip styling | Match mobile chip styling with shadow + check icon | Medium | |
| 39 | Interests | Suggest Topic | Dialog for suggesting new topics | No suggest topic feature | Missing feature | Add suggest topic dialog | Low | |
| 40 | Navigation | Bottom Navigation | 4 tabs: Home, My Learning, Forums, Profile with animated pill selection (AnimatedContainer 200ms, primary bg, blur backdrop) | Mobile: 5-tab bottom bar (Home, Courses, Learning, Community, Profile); Desktop: top nav | Different tab count, labels, icons, and styling | Match 4-tab navigation with pill selector, glass effect, haptic-matching transitions | Critical | |
| 41 | Navigation | Quick Actions (Home) | 4 GlassIconButtons: Notifications (with dot), Cart (with badge), History, Wishlist | Desktop: Language, Theme, Cart, User card; Mobile bottom: Home/Courses/Learning/Community/Profile | Different quick actions structure | Add notification dot, cart badge, history, wishlist to header actions | High | |
| 42 | Home | Hero Section | SliverAppBar with collapsible hero: custom-painted animated programming shapes, hero image, Arabic copy text | Landing page: marketing hero with teacher cutout, floating badges | Completely different approach | Mobile has app-home layout; web has marketing landing; when logged in, web uses StudentHome which is different from mobile HomeScreen | Critical | Need to align the logged-in home experience |
| 43 | Home | Search Bar | GlassSearchBar: height 46, border radius 12, tune icon for filters, readOnly → navigates to search | Simple `<input type="search">` with client-side filter | Different search bar implementation | Replace with GlassSearchBar-like component matching mobile style | High | |
| 44 | Home | Banner Carousel | PageView auto-scroll (5s), gradient overlay on banners, dots indicator (animated width) | No banner carousel | Missing banner carousel | Add banner carousel with auto-scroll, gradient overlay, dot indicators | Critical | |
| 45 | Home | Category Chips | Horizontal scrolling category chips with icons, "All" first, animated selection | No category section on home | Missing categories section | Add horizontal category chips matching mobile | High | |
| 46 | Home | Course Sections | Multiple sections: Featured, Popular, New Arrivals, Flash Sale, Recommended, Continue Learning, Stories, Parent Portal | StudentHome: Continue Learning grid + Quick Access grid | Missing most home sections | Add Featured/Popular/New/Flash Sale/Recommended/Continue Learning sections | Critical | |
| 47 | Home | Flash Sale | Flash sale header with gradient red, countdown timer, horizontal card list | No flash sale section | Missing flash sale | Add flash sale section with countdown timer | High | |
| 48 | Home | Continue Learning | Dedicated card with thumbnail, progress bar, "CONTINUE LEARNING" label, resume button | Simple grid with progress bars | Less detailed cards | Enhance with matching card design | High | |
| 49 | Home | Stories Section | Horizontal avatar list with gradient rings, LIVE badge | No stories section | Missing stories | Add stories section | Low | |
| 50 | Home | Parent Portal | Card with family icon, primary bg, enter button | Dedicated /parent-portal page (separate) | Different placement; mobile has it on home, web has separate page | Add parent portal card on home page | Medium | |
| 51 | Home | Loading Skeleton | Custom shimmer with animated gradient, matching real layout | "Preparing courses..." text | No skeleton loading | Implement shimmer skeleton matching mobile patterns | High | |
| 52 | Course Details | Layout | Full CustomScrollView: hero → info → instructor compact → stats grid → what you learn → curriculum → instructor full → reviews → bottom price bar | 2-col layout: left (media + description + objectives + curriculum + reviews) + right (sticky sidebar with pricing + actions) | Different layout approach | Desktop sidebar is acceptable adaptation, but the sections and order must match mobile; mobile has no sidebar on mobile | Medium | Acceptable desktop adaptation if sections match |
| 53 | Course Details | Stats Grid | 2x2 grid: Lessons, Hours, Quizzes, Certificate with icons | Stat pills (rating, lessons, duration) in header | Different stat presentation | Add 2x2 stats grid matching mobile | High | |
| 54 | Course Details | What You Learn | Container with check icons, max 6 items, "+N more" overflow | 2-col grid with Check icons | Similar but different styling | Align styling to mobile container | Medium | |
| 55 | Course Details | Curriculum | Expandable sections with AnimatedRotation chevron, lesson items with type icons, lock icons, preview badge | Expandable sections with simpler styling | Different section/lesson item styling | Match mobile styling: icon circles, type icons, preview badges | High | |
| 56 | Course Details | Reviews | Amazon-style rating overview: left (big number + stars + count) + right (5-bar distribution); review cards with report | ReviewsSection: average + star input + review list | Missing rating distribution chart | Add rating distribution bars | High | |
| 57 | Course Details | Bottom Price Bar | Fixed bottom bar with price + CTA (dynamic: Add to Cart / Continue Learning / etc.) | Sticky sidebar with pricing + actions | Different CTA placement (acceptable desktop adaptation) | Ensure CTA states match mobile: enrolled/inCart/free variations | Medium | |
| 58 | Course Details | Preview Video | Extracts YouTube ID → CoursePreviewPlayerScreen | iframe embed | Different video preview | Acceptable desktop difference | Low | |
| 59 | Course Details | Share/Report | PopupMenuButton with Share + Report options | No share or report buttons | Missing share and report | Add share + report functionality | Medium | |
| 60 | Course Details | Pricing Options | Bottom sheet with multiple pricing options, discount display | No pricing options selection | Missing pricing options | Add pricing options bottom sheet | High | |
| 61 | Course Player | Layout | CustomScrollView: video + header + sticky tab bar (5 tabs: Lectures, More, Q&A, Quizzes, Rating) + bottom action bar | 2-col: sidebar with curriculum + main area with video, lesson content, tabs | Different layout approach | Desktop sidebar is acceptable; tab content must match mobile 5 tabs | Medium | |
| 62 | Course Player | Video Players | 3 player types: CleanYouTubePlayer (primary), YouTubePlayerWidget (fallback), DirectVideoPlayerWidget | VideoPlayer component: HTML5 video or YouTube iframe API | Web has limited video controls | Add: playback speed controls, fullscreen, keyboard shortcuts | High | |
| 63 | Course Player | Fullscreen | FullscreenPlayerScreen: forced landscape, immersive, custom controls | No fullscreen mode | Missing fullscreen | Add fullscreen video mode | High | |
| 64 | Course Player | Progress Tracking | Auto-saves every 30s, tracks per-lesson position, auto-complete at 95% | Auto-saves every 10s, auto-complete at 95% | Different save interval | Align to 30s interval | Low | |
| 65 | Course Player | Lesson Types | Video, Article, Quiz, Assignment, Resource, Live, Document with type-specific icons and UIs | Video, Article (dangerouslySetInnerHTML), Quiz link, File download | Missing: assignment UI, live stream, document viewer | Add missing lesson type renderers | High | |
| 66 | Course Player | Notes | Full bottom sheet with add/delete/notes tab, timestamp badges | No notes functionality | Missing notes | Add notes tab with add/delete/timestamp | High | |
| 67 | Course Player | Bookmarks | Bottom sheet with bookmark list, "Go to Lesson" navigation | Bookmark button exists but non-functional | Bookmarks not implemented | Implement bookmark functionality | High | |
| 68 | Course Player | Q&A Section | In-player Q&A tab: ask question, upvote, instructor-highlighted answers | Separate /qa page with question/answer lists | Q&A is separated from player on web | Add Q&A tab in course player | High | |
| 69 | Course Player | Rating Section | In-player rating: Amazon-style overview + write review form + review cards | ReviewsSection only on course details page | Missing rating tab in player | Add rating tab in player | Medium | |
| 70 | Course Player | Course Completed | CompletionAnimation (trophy type) + certificate info dialog | No completion celebration/dialog | Missing course completion dialog | Add completion animation + certificate dialog | High | |
| 71 | Course Player | Mini Player | VideoMiniPlayerOverlay: floating mini-player when leaving player | No mini-player overlay | Missing mini-player | Add mini-player overlay | Medium | |
| 72 | Quizzes | Quiz Info | QuizInfoCard + QuizMetaGrid (2x2: time/questions/pass/attempts) + PreviousAttemptsList + animated "Start Quiz" button | Hero card + 4-col info grid (similar) + attempts list + Start button | Similar structure but different styling | Align styling to match mobile | Medium | |
| 73 | Quizzes | Quiz Taking | Custom option cards with radio/checkbox indicators, selected glow, question image support, progress bar, timer | Similar implementation with selected options and timer | Close match but different styling | Align option card styling, radio/checkbox indicators | Medium | |
| 74 | Quizzes | Timer | Timer with PulseAnimation when <60s, auto-submit on timeout | Timer turns red when <60s | Missing pulse animation | Add pulse animation to timer | Medium | |
| 75 | Quizzes | Submit Confirmation | Custom AlertDialog showing answered/unanswered stats | window.confirm() browser dialog | Uses native browser confirm instead of custom dialog | Replace with custom styled dialog | High | |
| 76 | Quizzes | Quiz Results | ScoreCircle (custom-painted), CompletionAnimation (trophy/check), answer review with explanations | Percentage display, pass/fail icon, answer review | Different result display styling | Match mobile's circular score + completion animation + explanation sections | High | |
| 77 | Quizzes | Answer Caching | QuizzesLocalDataSource caches answers locally | No answer caching; answers lost on page refresh | Missing answer persistence | Add localStorage answer caching | High | |
| 78 | Quiz | True/False type | `trueFalse` question type with auto-populated True/False options | Supported but styling differs | Minor styling | Align true/false option card styling | Low | |
| 79 | Cart | Layout | CustomScrollView: SliverAppBar + items list + coupon section + summary card + checkout button | 2-col grid: items column + summary sidebar | Different layout (sidebar acceptable on desktop) | Ensure card styling and pricing display match | Medium | |
| 80 | Cart | Item Cards | CartItemCard: thumbnail 60x60, title, instructor+rating row, price, remove button (error tinted) | Similar card with thumbnail, title, price, remove button | Different card styling | Match mobile card styling with instructor + rating row | High | |
| 81 | Cart | Coupon Section | Collapsible coupon with AnimatedCrossFade, applied coupon display (success message + close) | Coupon input with apply button, applied coupon state | Different coupon UI | Match mobile's collapsible coupon with animation | Medium | |
| 82 | Cart | Loading Skeleton | Custom shimmer matching cart layout | No skeleton loading | Missing skeleton | Add cart skeleton loading | Medium | |
| 83 | Cart | Empty State | EmptyStateType.cart: 200x200 illustration, gradient icon, animated entrance | ShoppingCart icon + "Your cart is empty" text | Different empty state styling | Match mobile's animated empty state with illustration | Medium | |
| 84 | Cart | Error Shake | ErrorShake animation on failed remove-from-cart | No error shake animation | Missing error animation | Add shake animation on cart errors | Low | |
| 85 | Checkout | Payment Flow | Manual payment only: Submit request → PaymentSuccess screen with WhatsApp contact | Paymob integration: card/wallet payment gateway | Completely different payment system | Critical business logic difference - requires product decision | Critical | |
| 86 | Checkout | Manual Payment Info | Info box explaining manual payment process | No manual payment info (uses Paymob) | Missing manual payment explanation | Add manual payment info section if manual payment retained | High | |
| 87 | Payment Success | Layout | Success icon (112x112 circle), title, subtitle, order ID tile, WhatsApp contact button, back to home | Simple card: icon (spinning/check/error), title, message, CTA | Different layout and no WhatsApp contact | Add WhatsApp contact button, order ID display with copy | High | |
| 88 | Payments History | Layout | 5-tab bar (All, Paid, Pending, Refunded, Cancelled) with count badges + Pull-to-refresh | Simple list of payment cards with status icons | Missing tab-based filtering | Add 5-tab filter bar with counts | High | |
| 89 | Payments History | Bottom Sheet | DraggableScrollableSheet with detailed payment breakdown | No detail bottom sheet | Missing payment detail modal | Add detailed bottom sheet matching mobile | Medium | |
| 90 | Forums | List Screen | Filter chips (All/Groups/Private), conversation cards (64x64 avatar, type badge, badges, unread styling) | Simple grid of forum cards with type badge | Missing filter chips, different card styling | Add filter chips, match card styling | High | |
| 91 | Forums | Chat Screen | ForumChatAppBar, MessageBubble (own/others bg, avatar, reactions, reply-to, swipe-to-reply, message options, reaction picker) | Simple chat window with basic message bubbles | Missing: reactions, reply-to, swipe-to-reply, message edit/delete, search | Add reactions, reply-to, swipe-to-reply, message options | High | |
| 92 | Forums | Group Management | CourseForumsManagementScreen + GroupMembersScreen with member management | No forum management interface | Missing admin/instructor forum management | Add forum management for instructors | High | |
| 93 | Direct Chat | Entire Feature | DirectChatScreen with read receipts (✓/✓✓), Dismissible swipe-to-reply, own emoji set (🔥 replaces 🙏) | /chat page: instructor sidebar + chat window with basic bubbles | Missing: read receipts, swipe-to-reply, different emoji set, message reactions | Add read receipts, swipe-to-reply, reactions | High | |
| 94 | Q&A | Within Player | Q&A tab inside course player with lesson-scoped questions | Separate /qa page with all questions | Q&A is not integrated into player | Add Q&A tab to course player | High | |
| 95 | Q&A | Ask Question | Full screen form OR bottom sheet with info card, validation (min 10/20 chars) | Toolbar button opening form inline | Different presentation but similar functionality | Match mobile validation rules | Medium | |
| 96 | Q&A | Instructor Badge | Instructor answers highlighted with primary bg + "Instructor" label + verified check | Similar highlighting with primary border + glow | Styling difference | Match mobile instructor highlight style | Low | |
| 97 | My Learning | Layout | ContinueLearningCard + FilterTabs (In Progress/Completed/All with counts) + EnrolledCourseCard list + Recommended section | Dashboard header + simple course grid with progress bars | Missing: filter tabs, continue learning card, recommended section | Add filter tabs, continue learning card, recommended section | High | |
| 98 | My Learning | Course Cards | EnrolledCourseCard: 64x64 thumbnail, progress bar + percentage, status badges (inactive/completed/expiry), resume button | Simple grid card with progress bar and "Continue Learning" button | Missing: detailed progress indicators, status badges, inactive/expiry states | Add status badges and detailed progress matching mobile | High | |
| 99 | My Learning | Pagination | ScrollController triggers loadMore() at 200px from bottom, page size 20 | No pagination (loads all at once) | Missing pagination | Add pagination with 20-item page size | Medium | |
| 100 | History | Layout | Header + LessonHistoryService-backed list of HistoryCards (lesson-centered: thumbnail, lesson title, course title, time ago) | Enrollment-based list (course-centered: course title, progress %, last accessed) | Different data model: mobile tracks per-lesson history, web tracks per-course | Align to per-lesson history approach | High | |
| 101 | Wishlist | Layout | Custom AppBar with back/delete buttons + glass backdrop cards + WishlistFilterTabs + WishlistBottomBar with total value + "Add All to Cart" | FeaturePageHero + simple grid of course cards + remove button | Missing: filter tabs, total value bar, "Add All to Cart" | Add filter tabs, total value bar, "Add All to Cart" button | High | |
| 102 | Wishlist | Card Styling | Glass effect cards with BackdropFilter, favorite button (GlassIconButton), time-ago footer with action button states | Simple card with heart button, add-to-cart | Different card styling | Match mobile glass card styling | Medium | |
| 103 | Notifications | Layout | Grouped by date (Today/Yesterday/date), notification cards with type-specific icons + "BounceIcon", swipe-to-delete, animated entrance | Simple list with type icon, "new" badge, title, body, date | Missing: date grouping, bounce animation, swipe-to-delete, mark-all-read button | Add date grouping, type-specific icons, swipe-to-delete | High | |
| 104 | Notifications | Types | 10+ notification types with specific icons and colors (instructorMessage, courseUpdate, quizResult, certificateIssued, etc.) | Generic Megaphone icon for all | Missing type-specific icons | Add per-type icons and colors | High | |
| 105 | Settings | Layout | SingleChildScrollView with sections: Preferences (language, dark mode, notifications), Legal & Support (help, privacy, terms), Delete Account, Version | Similar structure but different styling | Similar functionality, different visual styling | Align styling to match mobile section structure | Medium | |
| 106 | Settings | Language Switching | ExpansionTile inside card with English/Arabic options | Toggle button (Globe icon) in header | Different location and UI for language | Move language toggle into settings page matching mobile | Medium | |
| 107 | Settings | Help & Support | HelpSupportScreen: WhatsApp contact card with gradient | External links only (privacy page, terms page) | Missing WhatsApp support card | Add HelpSupport section with WhatsApp card | High | |
| 108 | Profile | Layout | Full profile page: avatar + name + email + stats (courses, streak) + menu items (instructor dashboard, edit profile, notifications, my learning, orders status, forums, wishlist, settings) + logout | Redirects to /settings | Missing separate profile page with stats and menu | Create separate /profile page matching mobile | Critical | |
| 109 | Profile | Stats | Courses count + Streak count in card with divider | No stats display | Missing stats | Add course + streak stats | Medium | |
| 110 | Profile | Menu Items | 8 menu items with icons | No profile menu | Missing profile menu navigation | Add menu items with icons | High | |
| 111 | Edit Profile | Entire Screen | Full form: avatar upload, cover image (instructor), name, phone, instructor fields (headline, bio, expertise, social links) | No edit profile screen | Missing edit profile | Create /edit-profile page with all mobile fields | Critical | |
| 112 | Instructor Dashboard | Entire Feature | 14-tab dashboard: Dashboard, My Courses, Students, Forums, Enrollments, Purchase Requests, Earnings, Coupons, Quizzes, Q&A, Reviews, Categories, Banners, Settings | No instructor dashboard | Completely missing | Build complete instructor dashboard with all 14 tabs | Critical | |
| 113 | Logout | Confirmation | ResponsiveAlertDialog (destructive) before logout | No confirmation dialog | Missing logout confirmation | Add confirmation dialog matching mobile | High | |
| 114 | Categories | Screen | CategoriesScreen with 10 hardcoded categories, icon + color + course count | No categories page | Missing categories page | Add /categories grid matching mobile | High | |
| 115 | Course Search | Filter | CourseFilterScreen: full-page filter with categories (multi-select), price range slider, level chips, rating options | Expandable filter panel with 7 dropdowns | Different filter UI | Match mobile's full-page filter approach | Medium | |
| 116 | Course Search | Recent Searches | Recent Searches section with clear all + search chips | No recent searches | Missing recent searches | Add recent searches section | Medium | |
| 117 | Certificates | Screen | Referenced in CompletionAnimation and notification types | /certificates page with grid of certificate cards | Web has certificates page not prominently in mobile | Verify certificate data matches | Low | |
| 118 | Global | Haptic Feedback | HapticFeedback on many interactions (lightImpact, mediumImpact, selectionClick) | No haptic (N/A on web) | Platform limitation | Acceptable difference | N/A | |
| 119 | Global | Animations | Comprehensive: SlideFadeIn, FadeIn, ScaleIn, StaggeredList, BounceIcon, PulseAnimation, ErrorShake, ExpandableCard, AnimatedCard, CompletionAnimation, SwipeToDelete | GSAP-based: useFadeIn, useStagger, usePageTransition | Different animation library and patterns | Implement equivalent animations in React | High | |
| 120 | Global | Offline Indicator | OfflineIndicator: animated banner with retry | No offline detection or indicator | Missing offline indicator | Add connectivity detection and offline banner | Medium | |
| 121 | Global | Report Screen | Full-screen ReportScreen with reason chips, description field, pending state display | No report functionality | Missing report feature | Add report screen matching mobile | High | |
| 122 | Global | Empty States | 17 EmptyStateType variants with custom illustrations + animations | Simple icon + text empty states | Missing animated illustration empty states | Add animated empty states matching mobile types | High | |
| 123 | Global | Error States | 5 ErrorType variants (network, server, notFound, unauthorized, generic) with 3 display densities | No consistent error state handling | Inconsistent error handling | Implement mobile's ErrorState component with all variants | High | |
| 124 | Global | Loading States | AppLoadingState with 3 display densities + shimmer skeletons | "Loading..." text or spinner | Missing skeleton loading states | Implement shimmer skeleton loading | High | |
| 125 | Global | Shared Components | AppButton (6 variants, 3 sizes, press scale animation), AppCard (3 variants, glass glow), AppTextField (focus glow animation), AppBackButton, ResponsiveDialog | No shared component library | Missing shared component library | Build React equivalents of AppButton, AppCard, AppTextField, etc. | Critical | |

---

## Missing Features (Mobile → Web)

1. **Email Verification Flow** — Awaiting verification view with resend
2. **OTP-based Password Reset** — Current web uses magic link, mobile uses OTP
3. **Multi-Step Registration** (4-stage wizard)
4. **Instructor Dashboard** (14-tab full management interface)
5. **Edit Profile Screen** (avatar upload, cover image, all fields)
6. **Separate Profile Screen** (stats + menu items)
7. **Forum Management** (instructor course forum controls, group member management)
8. **Course Completion Dialog** (trophy animation + certificate info)
9. **Mini Video Player Overlay** (picture-in-picture when leaving player)
10. **Notes in Course Player** (add/delete/timestamp)
11. **Bookmarks in Course Player**
12. **Announcements in Course Player**
13. **Q&A Tab inside Course Player**
14. **Rating Tab inside Course Player**
15. **Categories Screen** (dedicated grid page)
16. **Recent Searches** in course search
17. **Streak/Progress Stats** on profile
18. **WhatsApp Support Contact** from settings
19. **Cart Coupon Collapsible Section** with animation
20. **"Add All to Cart" on Wishlist**
21. **Wishlist Value Bar** (total value + savings)
22. **Payment History Tabs** (All/Paid/Pending/Refunded/Cancelled with counts)
23. **Payment Detail Bottom Sheet**
24. **Read Receipts in Direct Chat** (✓/✓✓)
25. **Message Reactions** (emoji reactions on messages)
26. **Swipe-to-Reply** in chat
27. **Message Edit/Delete** in chat
28. **Report Screen** (report courses/reviews with reason selection)
29. **Notification Type Icons** (type-specific icons and colors)
30. **Notification Date Grouping** (Today/Yesterday/date)
31. **Swipe-to-Delete Notifications**
32. **My Learning Filter Tabs** (In Progress/Completed/All)
33. **My Learning Recommended Section**
34. **Continue Learning Card** (dedicated prominent card on home)
35. **Banner Carousel** with auto-scroll
36. **Flash Sale Section** with countdown timer
37. **Stories Section** on home
38. **Course Details Stats Grid** (2x2)
39. **Course Details Rating Distribution** (5-bar chart)
40. **Course Details Share Button**
41. **Course Details Pricing Options Sheet**
42. **Instructor Registration Block** (disabled on mobile)
43. **Country Code Phone Selector** in registration
44. **Custom Validation Messages** (Arabic/English)
45. **Answer Caching** in quizzes (localStorage)
46. **Fullscreen Video Player**
47. **Video Playback Speed Controls**
48. **Lesson History** (per-lesson watch history)

---

## Extra Features (Web → Mobile, not in Mobile)

1. **Lime/Chartreuse Accent Color** — `#DDFB55` used extensively on web; doesn't exist in mobile
2. **Plasma Color** — `#B87CFF`; not in mobile design system
3. **Changa Display Font** — Not used in mobile (mobile uses Almarai exclusively)
4. **Paymob Payment Gateway** — Web uses Paymob card/wallet; mobile uses manual payment + WhatsApp
5. **Checkout Billing Form** — Name/Phone billing form on web; mobile doesn't have this
6. **Parent Portal Page** — `/parent-portal` with email lookup; mobile only shows a card on home linking to the same feature concept
7. **Apple & Facebook Social Login** — Shown on web but hidden on mobile (showApple: false, showFacebook: false)
8. **Instructor Role Selector** — On sign-up; mobile explicitly blocks instructor registration
9. **Chalk/Brand Purple Dark Mode** — Web's primary dark is purple `#9b4dff`; mobile's is blue `#2563EB`

---

## Design System Differences

### Colors

| Token | Mobile | Web (Light) | Web (Dark) | Match? |
|-------|--------|-------------|------------|--------|
| Primary | `#2563EB` | `#2563EB` | `#9b4dff` | ✗ Dark mismatch |
| Primary Dark | `#1D4ED8` | `#1D4ED8` | `#7c26e8` | ✗ Dark mismatch |
| Primary Light | `#BFDBFE` | `#DBEAFE` | `#1b1632` | ✗ |
| Background | `#EFF6FF` | `#F7F7FB` | `#07040F` | ✗ |
| Surface | `#FFFFFF` / `#0F172A` | `rgba(255,255,255,0.86)` / `rgba(22,15,37,0.86)` | ✗ Opacity + color |
| Card Dark | `#172033` | — | `rgba(27,18,46,0.9)` | ✗ |
| Text Main | `#0F172A` / `#FFFFFF` | `#171024` / `#f7f4ff` | ✗ |
| Text Muted | `#4B5563` / `#D1D5DB` | `#625A70` / `#c9c1dc` | ✗ Purple tint |
| Border | `#E5E7EB` / `#374151` | `rgba(64,44,92,0.14)` / `rgba(178,133,255,0.2)` | ✗ Purple tint |
| Rating | `#B47D00` | `#E59819` | ○ Close but not exact |
| Success/Error/Warning | `#22C55E` / `#EF4444` / `#F59E0B` | Same | ✅ |
| Accent/Lime | None | `#DDFB55` | ✗ Does not exist in mobile |
| Plasma | None | `#B87CFF` / `#C59BFF` | ✗ Does not exist in mobile |

### Typography

| Aspect | Mobile | Web | Match? |
|--------|--------|-----|--------|
| Font Family | Almarai (all text) | Readex Pro / Plus Jakarta Sans / Changa | ✗ |
| Display weights | w700-w900 | 500-800 | ✗ |
| Body weight | w400 | 400 | ✅ |
| Label weight | w500 | varies | ○ |
| Letter Spacing | -0.5 to 0.5 | No defined system | ✗ |
| Line Heights | 1.2-1.5 defined per style | No defined system | ✗ |

### Icons

| Aspect | Mobile | Web | Match? |
|--------|--------|-----|--------|
| Library | Material Icons (Flutter) | Lucide React | ✗ Completely different |
| Style | Filled/rounded | Outline (Lucide) | ✗ |
| Sizes | xs=12, sm=14, md=18, lg=24 | No consistent sizing | ✗ |

### Buttons

| Aspect | Mobile | Web | Match? |
|--------|--------|-----|--------|
| Component | AppButton (6 variants, 3 sizes, scale press animation) | Various inline button styles | ✗ |
| Primary bg | `#2563EB` | gradient-bg (primary-dark to primary) | ○ Close |
| Border radius | 12 | 10-12 (inconsistent) | ○ |
| Press animation | scale 1.0 → 0.95, 100ms | None | ✗ |
| Haptic | lightImpact | N/A | N/A |

### Inputs

| Aspect | Mobile | Web | Match? |
|--------|--------|-----|--------|
| Component | AppTextField (focus glow animation) | Standard HTML inputs | ✗ |
| Label | Above field, 13-14px w500 | Placeholder text | ✗ Different approach |
| Border | 12px radius, primary focus, error error | 10px radius, primary focus | ○ Close |
| Focus glow | Primary shadow animation 200ms | None | ✗ |

### Cards

| Aspect | Mobile | Web | Match? |
|--------|--------|-----|--------|
| Component | AppCard (3 variants, glass glow, press animation) | Various div/article styles | ✗ |
| Border radius | 12 default | 20-26px (CSS modules) | ✗ |
| Glow shadow | Primary alpha 0.15-0.3 | Primary glow (different values) | ○ |
| Press effect | Scale 1.0 → 0.98, 100ms | Hover translateY | ✗ Different interaction |

### Navigation

| Aspect | Mobile | Web | Match? |
|--------|--------|-----|--------|
| Bottom nav | 4 tabs with glass backdrop + pill selector | 5 tabs (mobile) / top nav (desktop) | ✗ |
| Tab animation | AnimatedContainer 200ms | CSS transitions | ○ |
| Tab icons | Material: home, play_circle, forum, person | Lucide icons | ✗ |
| Active state | Primary pill bg + border | Underline gradient | ✗ |

### Dialogs

| Aspect | Mobile | Web | Match? |
|--------|--------|-----|--------|
| Component | ResponsiveDialog + ResponsiveAlertDialog | window.confirm() | ✗ |
| Background | cardDark/white with r16 | N/A | ✗ |
| Destructive | Error-colored confirm button | N/A | ✗ |
| Barrier | black alpha 0.7 | N/A | ✗ |

### Forms

| Aspect | Mobile | Web | Match? |
|--------|--------|-----|--------|
| Validation | Custom validators with Arabic/English messages | HTML5 required only | ✗ |
| Phone input | PhoneInputField with country picker | Plain text input | ✗ |
| Error display | Inline error messages + Toasts | Alert banners | ○ |

---

## Implementation Roadmap

### Phase 1 — Critical Blockers (Weeks 1-3)
1. **Align Design System**: Replace all colors, fonts, spacing, shadows, border-radius with mobile tokens
2. **Replace Icon Library**: Switch from Lucide to Material Icons
3. **Build Shared Component Library**: AppButton, AppCard, AppTextField, GlassSearchBar, GlassIconButton, EmptyState, ErrorState, LoadingState, ResponsiveDialog, SectionHeader, UserAvatar, RatingStars, PriceTag
4. **Fix Login/Register**: Remove Apple/Facebook, add brand header, add multi-step registration, add email verification, add phone country code, add custom validation, block instructor sign-up
5. **Fix Forgot Password**: Implement OTP-based flow
6. **Build Profile Page**: Separate from settings, add stats, add menu items

### Phase 2 — UI Parity (Weeks 4-7)
7. **Home Page Overhaul**: Add banner carousel, category chips, course sections (featured/popular/new/flash sale/recommended/continue learning), matching card styles
8. **Course Details**: Add stats grid, rating distribution bars, pricing options sheet, share + report buttons
9. **Course Player Overhaul**: Add 5 tab system (lectures, more, Q&A, quizzes, rating), add fullscreen, add playback speed, improve video controls
10. **Cart/Wishlist**: Match card styling, add coupon collapsible, add wishlist value bar + "Add All to Cart"
11. **My Learning**: Add filter tabs, continue learning card, recommended section, pagination
12. **Notifications**: Add type-specific icons, date grouping, swipe-to-delete, mark-all-read

### Phase 3 — UX Parity (Weeks 8-10)
13. **Forums/Chat**: Add message reactions, swipe-to-reply, read receipts, message edit/delete, forum management
14. **Q&A Integration**: Add Q&A tab inside course player
15. **Course Completion Flow**: Add completion animation + certificate dialog
16. **Payment History**: Add 5-tab filtering, payment detail sheet
17. **History**: Switch to per-lesson tracking
18. **Settings**: Add HelpSupport WhatsApp card, move language toggle

### Phase 4 — Component Parity (Weeks 11-12)
19. **Animations**: Implement SlideFadeIn, FadeIn, ScaleIn, StaggeredList, BounceIcon, PulseAnimation, ErrorShake, AnimatedCard, CompletionAnimation in React
20. **Loading Skeletons**: Implement shimmer skeletons for every screen
21. **Empty States**: Implement 17 EmptyStateType variants with animations
22. **Error States**: Implement 5 ErrorType variants with 3 display densities
23. **Offline Indicator**: Add connectivity detection banner

### Phase 5 — Responsive Refinement (Weeks 13-14)
24. **Bottom Navigation**: Match mobile's 4-tab glass nav with pill selector on mobile viewports
25. **Adaptive Layout**: Ensure desktop uses appropriate wider layouts while maintaining mobile design language for all components
26. **Responsive Dialogs**: Ensure ResponsiveDialog adapts width as on mobile
27. **Tab/Sidebar Adaptation**: Course player sidebar on desktop, bottom tabs on mobile

### Phase 6 — Final QA (Weeks 15-16)
28. **Visual Regression Testing**: Screenshot comparison on every screen
29. **Interaction Testing**: Every button, link, form, validation matches mobile
30. **State Testing**: Every loading/empty/error/success state matches mobile
31. **Dark/Light Mode Testing**: Every screen in both modes
32. **RTL Testing**: Every screen in Arabic (RTL) and English (LTR)
33. **Cross-Browser Testing**: Chrome, Firefox, Safari, Edge

---

## QA Checklist

### Authentication
- [ ] Login screen matches mobile layout with brand header, tab switcher, field styling
- [ ] Multi-step registration (4 stages) with phone country selector
- [ ] Email verification flow with resend button
- [ ] OTP-based password reset (not magic link)
- [ ] Only Google social login shown (Apple/Facebook hidden)
- [ ] Instructor registration blocked
- [ ] Custom Arabic/English validation messages
- [ ] Post-registration interests selection with min 3 requirement

### Navigation
- [ ] 4-tab bottom navigation (Home, My Learning, Forums, Profile) on mobile
- [ ] Glass backdrop effect with pill selector animation
- [ ] Quick action buttons in header (notifications dot, cart badge)

### Home
- [ ] Collapsible hero with search bar
- [ ] Banner carousel with auto-scroll and dot indicators
- [ ] Category chips with icons
- [ ] Featured/Popular/New/Flash Sale/Recommended course sections
- [ ] Continue Learning card with progress bar
- [ ] Shimmer loading skeleton

### Course Details
- [ ] Stats grid (Lessons/Hours/Quizzes/Certificate)
- [ ] Rating distribution (5-bar chart)
- [ ] Pricing options bottom sheet
- [ ] Share + Report buttons
- [ ] Bottom price bar with dynamic CTA states

### Course Player
- [ ] 5-tab sticky tab bar (Lectures, More, Q&A, Quizzes, Rating)
- [ ] Fullscreen video with custom controls
- [ ] Playback speed control
- [ ] Notes tab with add/delete/timestamp
- [ ] Bookmarks tab
- [ ] Course completion dialog (trophy + certificate)
- [ ] Mini player overlay when exiting
- [ ] Next Lesson + Resources bottom bar
- [ ] Quiz section within player

### Quizzes
- [ ] Quiz info with animated meta grid
- [ ] Timer with pulse animation when <60s
- [ ] Custom submit confirmation dialog (not window.confirm)
- [ ] Answer caching (survives page refresh)
- [ ] Result: circular score + completion animation + answer review with explanations

### Cart/Payments
- [ ] Cart item cards with instructor + rating row
- [ ] Collapsible coupon section with animation
- [ ] Payment history with 5-tab filtering
- [ ] Payment detail bottom sheet
- [ ] WhatsApp contact on payment success

### Chat/Forums/Q&A
- [ ] Message reactions (6 emojis)
- [ ] Swipe-to-reply
- [ ] Read receipts (✓/✓✓)
- [ ] Message edit/delete
- [ ] Forum management for instructors
- [ ] Q&A tab inside course player

### Profile/Settings
- [ ] Separate profile page with stats
- [ ] Edit profile page with all fields (avatar, cover, social links)
- [ ] WhatsApp help card
- [ ] Logout confirmation dialog

### Design System
- [ ] Almarai font loaded and used everywhere
- [ ] All colors match AppColors tokens
- [ ] All spacing matches 8px grid
- [ ] All border-radius values from AppRadius
- [ ] Material Icons used throughout
- [ ] Dark mode uses blue palette (not purple)
- [ ] All cards use AppCard styling with glow shadow
- [ ] All buttons use AppButton with press scale animation
- [ ] All inputs use AppTextField with focus glow
- [ ] Lime/plasma accent colors removed

### States
- [ ] Shimmer skeleton on every loading screen
- [ ] Animated empty states with illustrations
- [ ] ErrorState with retry on every error screen
- [ ] Offline indicator banner
- [ ] Toast notifications for success/error messages

### Instructor Dashboard
- [ ] 14-tab dashboard with all content tabs
- [ ] Course editor (5 steps)
- [ ] Student management (details, progress, enrollments)
- [ ] Quiz management (create, edit, questions, preview)
- [ ] Coupon editor
- [ ] Earnings history with filters
- [ ] Category/Banner management
- [ ] Purchase requests management

---

## Executive Summary

### Overall Parity Score: 28%

### Major Issues (Critical): 15
- Font family mismatch (Almarai vs 3 different web fonts)
- Color system mismatch (purple dark mode vs blue; lime accent doesn't exist in mobile)
- Icon library mismatch (Lucide vs Material Icons)
- Missing shared component library
- Missing instructor dashboard (entire 14-tab feature)
- Missing edit profile screen
- Missing email verification flow
- Different password reset mechanism (OTP vs magic link)
- Missing profile screen (redirects to settings)
- Instructor registration not blocked on web
- Social login shows Apple/Facebook that mobile hides
- Registration is single-page vs 4-stage wizard
- Bottom navigation tabs and styling completely different
- Home screen content sections mostly missing
- Missing course player Q&A/Rating tabs

### Minor Issues (Medium/Low): 60+

### Screens Completed: 8/30
- /forgot-password (basic, but missing OTP flow)
- /search (basic, but missing recent searches and full-page filter)
- /quiz (basic, but styling and features differ)
- /cart (basic, but styling differs)
- /checkout (different payment system)
- /settings (basic, but missing HelpSupport)
- /payments (basic, but missing tabs)
- /forums (basic, but missing chat features)

### Screens Needing Work: 22/30
- /login — major rework needed
- /interests — medium work
- /home — major rework (logged-in experience)
- /courses/[id] — medium work (stats grid, rating chart, pricing)
- /learn/[courseId] — major work (5 tabs, notes, bookmarks, completion)
- /my-learning — major work (filter tabs, continue learning, recommended)
- /wishlist — medium work (filter tabs, value bar)
- /notifications — major work (type icons, grouping, swipe)
- /forums — major work (reactions, reply, management)
- /forums/[id] — major work (reactions, reply-to, options)
- /chat — major work (read receipts, reactions, swipe-reply)
- /qa — medium work (validation, integration into player)
- /history — major work (switch to lesson-based)
- /payments — medium work (add tabs)
- /profile — needs creation
- /edit-profile — needs creation
- /categories — needs creation
- /instructor — needs entire dashboard creation
- And 5+ more sub-screens for instructor features
