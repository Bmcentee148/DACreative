# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-page marketing site for **DA Creative Co.**, a boutique social media management and photography studio. Built by Benchwork Digital for the client. The brand went through a naming detour (earlier revisions say "Focus & Feed") and landed back on DA Creative Co. — if you find a stale Focus & Feed / F&F reference outside `index_old.html`, it's a bug.

There is no build system, no package manager, no tests, and no dependencies to install. `index.html` is the entire site: HTML, CSS (in one `<style>` block), and JS (in one `<script>` block at the bottom of `<body>`).

## Working on it

- **Preview:** open `index.html` directly in a browser, or `python3 -m http.server 8000` and visit `http://localhost:8000`.
- **Deploy:** the contact form uses Netlify Forms (`data-netlify="true"`, `netlify-honeypot="bot-field"`, plus a hidden `form-name` input). The form only functions on a Netlify deploy; it will not submit locally.
- `index_old.html` is a manual backup of a previous revision, not a live page. Don't edit it as part of a change; leave it alone unless asked.

## Structure of `index.html`

Roughly: `:root` custom properties → base/component CSS → reduced-motion + forced-light overrides → responsive media queries → markup → script.

Sections in document order, each with an anchor id used by both the desktop nav and the mobile drawer: hero, values, `#about`, `#why`, `#services`, `#work`, `#contact`, footer.

## Conventions that matter

**Colors go through CSS variables.** The palette (`--cream`, `--ink`, `--gold`, `--blush`, `--espresso`, `--line`, …) is defined once in `:root`. Never hardcode a hex in a rule — add or reuse a variable.

**The site is deliberately light-only.** `color-scheme: only light` is set in three places, and there's a `@media (prefers-color-scheme: dark)` block that re-declares the whole palette and `!important`-overrides every surface. This exists to defeat forced dark mode in iOS/in-app browsers. **If you add a new section or surface with its own background, add a matching override to that dark-mode block** or it will invert on some devices.

**Mobile-first, min-width breakpoints only:** 620px (3-up grids), 760px (clients/nudge), 880px (main desktop layout — this is also where `.nav-links`/`.nav-cta` appear and `.burger` disappears).

**Images live in `images/` and are referenced by path.** They used to be inlined as base64 data URIs, which is why `index.html` was ~185 KB; it's ~43 KB now. Don't reintroduce data URIs — add new imagery as a file under `images/`.

**`src/` holds the full-res originals and is gitignored.** Only the derivatives in `images/` are committed and served — nothing in `src/` is referenced by `index.html`. It currently holds the founder photos, the logo original, `Logo_Canva.png` (the superseded Focus & Feed mark, reference only), and `Client_logo.png` (1200×630, purpose not yet established — unused). Because it's ignored, **`src/` is not backed up by git**; treat the client's originals as living only on this machine unless they're archived elsewhere.

`images/dacreative-logo.webp` is a 1000×716 lossless WebP (78KB); the full-res 2000×2000 original is `src/DACreative_logo.png`.

**The web copy is cropped to the artwork.** The supplied original is a 2000×2000 square in which the mark occupies only ~53% of the canvas (16% dead space above, 22% below), so sizing it by the canvas renders it visibly smaller than it should be. The shipped crop is the alpha bounding box — offset 103,317 at 1735×1241 — giving a true 1.398:1 aspect. Re-crop from the original if you ever regenerate:

```sh
sips -c 1241 1735 --cropOffset 317 103 src/DACreative_logo.png --out /tmp/logo-crop.png
cwebp -lossless -z 9 -q 100 -resize 1000 0 -alpha_filter best /tmp/logo-crop.png -o images/dacreative-logo.webp
```

Because the crop removes the built-in padding, `.hero-logo`'s bottom margin supplies all the breathing room below the mark — don't reduce it assuming the image has its own.

**Founder portraits.** `images/daniela.webp` and `images/alana.webp` are lossy WebP (q82, 800×1200) derived from `src/Daniela.JPG` and `src/Alana.JPG`. Use lossy for photographs; lossless is for the logo and flat art only.

The two originals arrived at different aspect ratios (2:3 and 4:5) with head sizes ~1.8× apart, which is why they're cropped rather than used as-is — an unmatched pair reads as accidental. Both are cropped to 2:3 with head scale brought within ~1.4×, keeping each subject's camera in frame:

```sh
sips -c 4000 2667 --cropOffset 700 707 src/Alana.JPG   --out /tmp/a.jpg   # from 4000x6000
sips -c 2700 1800 --cropOffset 0   300 src/Daniela.JPG --out /tmp/d.jpg   # from 2160x2700
cwebp -q 82 -resize 800 0 /tmp/a.jpg -o images/alana.webp
```

If either portrait is ever replaced, re-match the head scale — that, not the crop ratio, is what makes the pair look art-directed.

**Gotcha:** `<img>` `width`/`height` attributes are presentational hints that beat CSS `aspect-ratio` when both dimensions resolve. Any `img` rule using `aspect-ratio` must also set `height:auto`, or the attribute wins and `object-fit:cover` silently crops a zoomed slice. Both `.hero-logo` and `.portrait img` set it. 

WebP is used without a `<picture>` fallback on purpose — the original build already shipped a base64 WebP hero logo with no fallback, and Safari has supported it since 2020. `libwebp` is installed via Homebrew, so `cwebp`/`dwebp` are available for re-encoding:

```sh
cwebp -lossless -z 9 -q 100 -resize 1000 0 src/DACreative_logo.png -o images/dacreative-logo.webp
```

Use `-lossless` for the logo and any flat/line art. The mark is ~92% transparent pixels over about 60 opaque colors, so lossless costs little and avoids artifacts on the thin script strokes.

The logo is a **wreath badge with the "social media management" tagline baked into the artwork**, so it only works at hero size. The nav and footer deliberately use a Fraunces text wordmark instead ("DA <em>Creative</em> Co."), not the image — the badge at 48px nav height is illegible, and its dark-brown script would disappear on the espresso footer.

**Animation respects `prefers-reduced-motion`,** both via a CSS block that neutralizes `.reveal`/hover transitions and via a JS check in the likes-ticker (it renders the final number and returns early). Any new motion needs the same treatment.

**JS is vanilla, no framework, no globals beyond DOM lookups by id.** Four independent concerns: footer year, sticky-nav shadow class, mobile drawer open/close (`setMenu` handles `aria-expanded`, `aria-label`, and body scroll lock), `IntersectionObserver`-driven `.reveal` animations, and the phone-mockup likes counter.

**Accessibility is maintained deliberately** — `aria-label` on every nav/landmark, `:focus-visible` outlines, Escape closes the drawer. Preserve this when editing markup.
