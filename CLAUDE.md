# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A single-page marketing site for **D&A Creative Co.**, a boutique social media management and photography studio. Built by Benchwork Digital for the client.

**The name is "D&A Creative Co." — with the ampersand.** It comes from the founders, Daniela and Alana, and the client's own copy leans on a D&A → DNA wordplay ("every brand has its own DNA"), so the ampersand carries meaning and isn't decorative. Earlier revisions of this repo used "Focus & Feed" and then briefly "DA Creative Co." without the ampersand; both are stale. Any bare `DA Creative Co.`, `Focus & Feed`, or `F&F` outside `index_old.html` is a bug.

There is no build system, no package manager, no tests, and no dependencies to install. `index.html` is the entire site: HTML, CSS (in one `<style>` block), and JS (in one `<script>` block at the bottom of `<body>`).

## Working on it

- **Preview:** open `index.html` directly in a browser, or `python3 -m http.server 8000` and visit `http://localhost:8000`.
- **Deploy:** the contact form uses Netlify Forms (`data-netlify="true"`, `netlify-honeypot="bot-field"`, plus a hidden `form-name` input). The form only functions on a Netlify deploy; it will not submit locally.

  **Netlify rewrites the form tag at deploy.** It consumes `data-netlify` and `netlify-honeypot` during build-time form detection and strips them from the served HTML — `<form name="contact" method="POST" data-netlify="true" …>` ships as `<form method='POST' name='contact'>`. Never select the form on those attributes: it works locally and silently fails in production, where the JS finds nothing, skips binding, and the browser does a native POST to Netlify's default confirmation page. The submit handler selects `#contactForm` for this reason. More generally, local testing cannot catch this class of bug — check the deployed HTML with `curl https://dacreativeco.com/ | grep '<form'`.
- `index_old.html` is a manual backup of a previous revision, not a live page. Don't edit it as part of a change; leave it alone unless asked.

## Structure of `index.html`

Roughly: `:root` custom properties → base/component CSS → reduced-motion + forced-light overrides → responsive media queries → markup → script.

Sections in document order, each with an anchor id used by both the desktop nav and the mobile drawer: hero, values, `#about`, `#why`, `#services`, `#work`, `#contact`, footer.

## Conventions that matter

**Colors go through CSS variables.** The palette is defined once in `:root` and follows the client's brand board (`src/rebrand/`): `--ivory` (#F6F4F0 primary bg), `--sand` (#DCCEBB alternate sections/`.tint`), `--paper`/`--white` (#FFFFFF cards), `--ink` (#3A3A3A charcoal text), `--ink-soft` (muted body), `--blue` (#6A7C9A dusty blue — primary brand: filled buttons use the darker `--blue-deep` #4F5F79 for white-text AA), `--sage` (#50645A hover/secondary accent), `--taupe` (#B79F8A icons, dividers, ornaments, placeholder), `--charcoal` (footer). Never hardcode a hex in a rule — add or reuse a variable. **Contrast caveat:** the light `--blue` passes AA only for large text; small links/labels and white-on-blue buttons use `--blue-deep`. Verify with math when adding blue text (this bit twice during the rebrand).

**Fonts:** headings are **Cormorant Garamond** (`"Cormorant Garamond",Georgia,serif`, weight 600 — it's lighter than the old Fraunces, hence the bump), body is **Inter** (`"Inter",system-ui,sans-serif`). Both from Google Fonts. Italic Cormorant is the accent voice (hero `em`, `.about-kicker`, `.about-sign`, `.footer-tagline`).

**The site is deliberately light-only.** `color-scheme: only light` is set in three places, and there's a `@media (prefers-color-scheme: dark)` block that re-declares the whole palette and `!important`-overrides every surface. This exists to defeat forced dark mode in iOS/in-app browsers. **If you add a new section or surface with its own background, add a matching override to that dark-mode block** or it will invert on some devices.

**Mobile-first, min-width breakpoints only:** 620px (3-up grids), 760px (clients/nudge), 880px (main desktop layout — this is also where `.nav-links`/`.nav-cta` appear and `.burger` disappears).

**Images live in `images/` and are referenced by path.** They used to be inlined as base64 data URIs, which is why `index.html` was ~185 KB; it's ~43 KB now. Don't reintroduce data URIs — add new imagery as a file under `images/`.

**`src/` holds the full-res originals and is gitignored.** Only the derivatives in `images/` are committed and served — nothing in `src/` is referenced by `index.html`. It holds the founder photos, `Client_logo.png` (James Fowler, the featured client), and **`src/rebrand/`** — the current brand board: `logo.png` (horizontal logo), `submark.png` (circular badge, currently unused on the site), `ColorPallete.PNG` / `LogoandColors.jpeg` (the palette + typography spec). Also several superseded marks (`D&A_Logo.png`, `DACreative_logo.png`, `Logo_Canva.png`) kept only as archive. Because it's ignored, **`src/` is not backed up by git**; treat the client's originals as living only on this machine unless they're archived elsewhere.

`images/dacreative-logo.webp` is the hero logo — **lossy WebP q88 (118KB), 1000×629, aspect 1.592:1**, derived from `src/rebrand/logo.png`. Unlike the old flat mark, this one has a shaded peony and fine botanical linework, so it's lossy (lossless was 205KB) — treat it as photographic, not vector art.

**The source has no alpha (near-white `#FEFEFE` background), so it's knocked out to transparency** — the hero has gradient "blooms" behind the logo that a solid background would occlude as a visible box. A naive white-key would eat the pale sage sprigs, so `knockout.swift` (repo root; compiled with `swiftc`, since there's no ImageMagick/PIL) does a threshold-feathered distance-from-white alpha that **preserves true colors** (alpha ramps only over the 5–26 near-white band; art beyond stays fully opaque) and auto-crops to the artwork bbox. To regenerate:

```sh
swiftc -O knockout.swift -o knockout          # loads PNG, white->alpha, crops
./knockout src/rebrand/logo.png /tmp/logo.png
cwebp -q 88 -resize 1000 0 -alpha_q 100 /tmp/logo.png -o images/dacreative-logo.webp
```

Because the crop removes the built-in padding, `.hero-logo`'s bottom margin supplies all the breathing room below the mark — don't reduce it assuming the image has its own.

**Featured client.** `#work` shows one real client — James Fowler Physical Therapy (`@jamesfowlerpt`) — using the `.work-lead` two-column grid. It previously held three **invented** practices (Riverside Dermatology, Coastal Family Dental, Wellspring Pediatrics) with fabricated metrics; that markup is gone but `.clients` / `.client-card` / `.client-cover` / `.client-metric` CSS is deliberately kept so the grid can return when there are more clients (old markup is in git history).

`images/client-jamesfowler.webp` is lossless WebP from `src/Client_logo.png`. Two properties of the source drive the treatment: it has **no alpha** (opaque white bg) and its teal/slate is **off-palette**, so it sits on a pure-white `.featured-logo` card — hence `--white:#FFFFFF`, which exists only for this. `--paper` (`#FFFDFA`) would leave a visible seam against the logo's white. The artwork fills just 16.5% of the 1200×630 canvas, so it's cropped tight and the card's padding supplies the breathing room:

```sh
sips -c 237 546 --cropOffset 197 332 src/Client_logo.png --out /tmp/jf.png
cwebp -lossless -z 9 -q 100 -resize 600 0 /tmp/jf.png -o images/client-jamesfowler.webp
```

**Founder portraits.** `images/daniela.webp` and `images/alana.webp` are lossy WebP (q82, 800×1200) derived from `src/Daniela.JPG` and `src/Alana.JPG`. Use lossy for photographs; lossless is for the logo and flat art only.

The two originals arrived at different aspect ratios (2:3 and 4:5) with head sizes ~1.8× apart, which is why they're cropped rather than used as-is — an unmatched pair reads as accidental. Both are cropped to 2:3 with head scale brought within ~1.4×, keeping each subject's camera in frame:

```sh
sips -c 4000 2667 --cropOffset 700 707 src/Alana.JPG   --out /tmp/a.jpg   # from 4000x6000
sips -c 2700 1800 --cropOffset 0   300 src/Daniela.JPG --out /tmp/d.jpg   # from 2160x2700
cwebp -q 82 -resize 800 0 /tmp/a.jpg -o images/alana.webp
```

If either portrait is ever replaced, re-match the head scale — that, not the crop ratio, is what makes the pair look art-directed.

Each portrait caption links to that founder's **personal photography Instagram** (`@danielaalexandra.photography`, `@alanafrancesca.photography`) — used for now while there's no on-site portfolio. The footer Instagram icon points to Daniela's. There is no D&A company Instagram yet; if one appears, the footer icon should move to it.

**Gotcha:** `<img>` `width`/`height` attributes are presentational hints that beat CSS `aspect-ratio` when both dimensions resolve. Any `img` rule using `aspect-ratio` must also set `height:auto`, or the attribute wins and `object-fit:cover` silently crops a zoomed slice. Both `.hero-logo` and `.portrait img` set it. 

WebP is used without a `<picture>` fallback on purpose — the original build already shipped a base64 WebP hero logo with no fallback, and Safari has supported it since 2020. `libwebp` is installed via Homebrew, so `cwebp`/`dwebp` are available for re-encoding:

Use `-lossless` only for flat/line art with few solid colors (e.g. the James Fowler client logo). The hero mark is shaded, so it's lossy — see its section above. `libwebp`, `swiftc`, and `sips` are the only image tools available (no ImageMagick/PIL/numpy).

The logo is a **horizontal mark with "Strategy. Storytelling. Content that connects." baked into the artwork**, so it only works at hero size. The nav and footer deliberately use a Cormorant Garamond text wordmark instead ("D&amp;A <em>Creative</em> Co."), not the image — the detailed mark at 48px nav height is illegible, and it would disappear on the charcoal footer. The **favicon** (`favicon.ico` + `images/favicon-{16,32}.png` + `apple-touch-icon.png`) is the Cormorant Garamond ampersand, ivory on a `--blue-deep` tile — regenerate by typesetting `&` at weight 700 and downscaling (16px is soft but legible; Cormorant has no optical-size axis). The **client descriptor** under both wordmarks reads "Social Media Management & Content Creation".

**Animation respects `prefers-reduced-motion`,** both via a CSS block that neutralizes `.reveal`/hover transitions and via a JS check in the likes-ticker (it renders the final number and returns early). Any new motion needs the same treatment.

**JS is vanilla, no framework, no globals beyond DOM lookups by id.** Four independent concerns: footer year, sticky-nav shadow class, mobile drawer open/close (`setMenu` handles `aria-expanded`, `aria-label`, and body scroll lock), `IntersectionObserver`-driven `.reveal` animations, and the phone-mockup likes counter.

**Accessibility is maintained deliberately** — `aria-label` on every nav/landmark, `:focus-visible` outlines, Escape closes the drawer. Preserve this when editing markup.
