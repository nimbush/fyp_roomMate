# RoomMate Finder — Liquid Glass Design System

> Target design system for `roommate_finder/`. The current codebase (`lib/config/app_colors.dart`,
> `lib/widgets/custom_button.dart`, etc.) is a flat, single-mode Material baseline — this document
> describes where the UI is headed as screens are built/reworked, not what's already implemented.
> Adopt incrementally: new screens follow this system; existing screens migrate when touched.

## Design intent
A clean, modern **"Liquid Glass"** aesthetic (Apple's frosted / translucent depth
language) for a single brand — RoomMate Finder's orange palette. Every screen sits on a soft
ambient **mesh-gradient backdrop** with drifting blurred blooms. Content lives on
**frosted glass panels** — translucent, gaussian-blurred, saturation-boosted
surfaces with a hairline border (light) or a light-catching gradient rim (dark),
plus a soft ambient shadow, so cards float as layers of liquid glass above the
backdrop. Motion is calm; corners are generous; the palette comes entirely from
`AppColors`.

The system is **fully dual-mode**. Light mode is bright frost over a near-white
canvas; dark mode is pass-through smoked glass over a near-black canvas
(≈`#090A0C`) with luminous orange-tinted blooms behind it. A persisted
Light / Dark / System toggle lives in Settings.

## Brand palette (light → dark)
Single brand, no white-labelling — but every token is still a mode-aware getter, not a
hardcoded const, so dark mode isn't just "the same colors on a black background."

| Token | Light | Dark |
|---|---|---|
| primaryColor | `#FF6B35` | `#FF8C61` |
| accentInk (text/icon on accent) | `#FF6B35` | `#F2F1F4` (near-white) |
| accentRing | transparent | 55% primary |
| primarySoft (fill) | 8% primary | 20% primary |
| likeGreen / passRed | `#4CAF50` / `#FF5252` | unchanged (status colors don't invert) |

## Core token roles (mode-aware getters on `AppColors`)
Convert `AppColors` from `static const` fields to `static` getters that branch on a stored
`isDark` flag (set once at app root, mirroring `themeModeProvider`), since Dart `const` can't
be mode-aware.

- **Canvas**: `scaffoldBackground`, `backdropTop/Mid/Bottom`, `bloomA/B/C`
  (bright neutrals in light; dim orange embers in dark).
- **Glass**: `glassFill` / `glassFillStrong` / `glassFillSubtle` (translucent
  white in light; near-transparent smoke in dark), `glassBorderInk` (hairline),
  `glassHighlight`, `glassShadow(Soft)`.
- **Accent recipe** (chips, pills, icon tiles, selected filters, the swipe-deck
  action buttons — used everywhere): foreground `accentInk`, fill `primarySoft`,
  ring `Border.all(color: accentRing, width: 1.2)`. In light mode the ring is
  transparent, so the clean frost look is untouched; where light already had a
  hairline, branch: `isDark ? accentRing : glassBorderInk`, width
  `isDark ? 1.2 : 1.0`.
- **Text**: `textInk` / `textMuted` / `textFaint` (replace `textPrimary` /
  `textSecondary` / `textHint`). `textFaint` is for dark surfaces only where it
  reads; on the light nav bar unselected items use `textMuted`.
- **Full-primary exceptions in dark**: bottom-nav selected label; the floating
  action button on the discovery screen (like/super-like) when active.
  Everything else stays on the accentInk/ring recipe.

## Glass anatomy (`GlassContainer` — build once, reuse everywhere)
outer shadow Container → `ClipRRect` → `BackdropFilter` (gaussian blur composed
with a saturation matrix: ×1.45 dark / ×1.2 light) → Stack of: translucent
fill, dark-mode `RimPainter` gradient rim, hairline border, content.
Dark cards get NO extra styling inside — the container carries the whole look.

## Reusable components (`lib/widgets/`)
- **GlassScaffold** — screen root: ambient backdrop gradient + 2–3 drifting
  blurred blooms + watermark. Every screen uses it.
- **GlassContainer / GlassCard** — the glass atom / padded content block. Swipe
  deck cards, match cards, chat bubbles, and profile sections all sit on this.
- **MkAppBar** — frosted app bar for pushed screens.
- **MkButton** (replaces `custom_button.dart`) — the only button: solid
  (gradient + sheen + rim), `outline:`, `tonal:` variants; built-in `loading:`.
  Never raw `ElevatedButton`/`TextButton`.
- **showGlassDialog** — blurred-barrier dialog. The `AlertDialog` inside uses a
  **solid `surfaceColor` background** + `surfaceTintColor: Colors.transparent`
  + 22.r shape (translucent fills disappear on the dark canvas). Confirm
  dialogs (e.g. "Unmatch", "Delete account"): outline Cancel left, gradient
  action right, in a Row — never stacked `actions`.
- **showGlassDatePicker** — for date-of-birth / availability fields: hand-built
  glass calendar (full-screen blur + glowing selected-day cell).
- **GlassBottomNav** — frosted pill bar (Discovery / Matches / Chat / Profile)
  + floating glass circle for the primary tab.
- **DuotoneIcon** — icon treatment: `solar_icons` only (`SolarIconsBold` under
  `SolarIconsOutline` at 35% opacity). Chevrons / disclosure arrows are plain
  thin `SolarIconsOutline` — never duotone.
- MkTextField (replaces `custom_text_field.dart`), MkSearchField, MkListTile,
  StatusBadge (match status pills), SummaryCard, UiStateHandler.

## State surfaces
- **UiStateHandler** — the one place a screen maps loading / empty / error /
  success to UI. `onLoading:` takes a shape-matching placeholder; omit it and
  you get the centred spinner, which is only correct when the whole screen is
  unavailable (e.g. splash).
- **SkeletonList / SkeletonListCard / SkeletonShimmer** — shimmer placeholders
  that mirror the real card (avatar, title, subtitle rows), used for the
  discovery deck, matches list, and chat conversation list, so the layout
  doesn't jump when data lands. Base/highlight are derived from `isDark` at
  3–15% white/black. The sweep is skipped under reduced motion — the flat
  blocks still read as "loading".

## Motion
Motion here explains change; it never decorates. Everything checks
`MediaQuery.disableAnimations` and renders the final state when it's set.

- **StaggeredListItem** — list entrance (matches list, chat list): fade +
  0.92→1.0 scale, 50ms apart, **capped at 8 steps** so long lists don't leave
  items invisible below the fold. Wrap the item, not the list.
- **MkButton press** — 0.98 scale over 120ms, driven by a `Listener`; the tap
  stays on the inner `InkWell` (one tap owner per button).
- **Swipe deck card** — drag-follow with rotation proportional to horizontal
  offset; on release, either spring back to center or fly off-screen (~250ms)
  toward the swipe direction; like/pass stamp fades in as drag distance
  increases past a threshold.
- **Match celebration** — the "It's a Match!" overlay scales in with a light
  bloom pulse, ~300ms, then settles; respects reduced motion (cut straight to
  final state, no pulse).
- **Inline error reveal** — `AnimatedSize` 150ms under the field.
- Sheet/dialog entrances and screen transitions stay **unanimated** — they sit
  on `BackdropFilter`s (see Faux glass below). Animate inner content only.

## Form validation (profile edit, register, forgot-password screens)
Show every error at once on submit — inline under each field, red border on the
field — then scroll to the first invalid one (`GlobalKey` per field in visual
order + `Scrollable.ensureVisible`). Never a queue of snackbars. Errors stay
hidden until the first submit, then update live. Each error is a getter derived
from state, so it can't go stale. Copy names the fix, not the rule (e.g. "Enter
a budget between your min and max" not "Invalid budget range").

## Faux glass (Impeller rule)
Only ONE `BackdropFilter` may be live at a time and never nested. Anything
sitting on an already-blurred surface (the floating like/pass buttons on the
swipe card, unread-count badge on a chat tile, chips on a profile card) fakes
glass with translucent fill + rim only. Sheets that open the calendar/dialog
drop their own blur first. Never animate a blur.

## Sizing
flutter_screenutil everywhere: `.sp` fonts/icons, `.w` horizontal, `.h`
vertical, `.r` radii and circles (both axes). Exempt: line-height multipliers,
letterSpacing, hairlines, shadows/offsets, opacities, durations.

## Adding a new screen — checklist
1. `GlassScaffold` root, `MkAppBar` if pushed, content in `GlassCard`s.
2. Colors only via `AppColors.*`; accents via the accentInk/primarySoft/
   accentRing recipe; branch on `AppColors.isDark` only for layout-level
   differences, never restyle shared tokens.
3. Handle all data states (loading / empty / error / retry) via UiStateHandler —
   `onLoading: () => const SkeletonList()` for anything list-shaped (discovery
   deck, matches, chat).
4. Empty states distinguish "no matches yet" from "no results for this filter"
   from a genuine network/API error, and offer the way out (adjust filters,
   retry, etc).
5. Lists get `RefreshIndicator` and `StaggeredListItem`; forms follow the
   inline-validation pattern above.
6. Any `showDialog` / `showModalBottomSheet` on a screen with text fields is
   preceded by unfocusing and awaiting a frame, so the keyboard doesn't spring
   back on dismiss.
7. Verify in BOTH light and dark mode before calling a screen done.
8. For anything involving focus, keyboard, gestures, or swipe-deck timing,
   test on a real device/emulator — simulator input timing can hide bugs.
