---
name: brand-dossier
description: Research a prospect/company/creator (from names or URLs) and produce a Bold demo-prep brand dossier — a folder with a paste-ready markdown file (org context, persona, tone, topics, transcription dictionary, conversation starters) plus downloaded logos and extracted brand colors. Use when preparing a Bold demo tenant for a prospect, or when asked to "research X for a demo", "make a dossier", or "brand research".
---

# Brand Dossier (Bold Demo Factory — Pass 1)

Produce everything about a prospect that is knowable **before** their videos are imported, as one folder Marcel can copy-paste from into Bold's admin. This is Pass 1 of BOLD-1817; persona voice and conversation starters get *provisional* drafts here and are refined later from actual transcripts (Pass 2/3).

## Inputs

Any mix of: company name, person name, website URLs, LinkedIn URLs, YouTube channel, social handles. If given only a name, first find the canonical web presence (official site, LinkedIn, YouTube) via web search and confirm you have the right entity before going deep — say what you matched on.

## Research procedure

Be thorough; follow links. Time-box to what a careful human would do in ~30 minutes.

1. **Site sweep**: fetch every given URL. From the homepage follow: About/Team, product/offer pages, footer links, press/media page. Capture: what they do, who it's for (audience/ICP), the offer (course, membership, clinic, SaaS…), principals with credentials/titles, content themes, named products/frameworks/programs.
2. **Socials**: find LinkedIn (company + principal), X/Instagram handles, podcast feeds. LinkedIn blocks plain fetches — use browser tools (Playwright MCP) if available in this session (local machine has sessions); if not reachable, mark LinkedIn-derived fields as gaps rather than guessing. For X research, use the `x-read` skill if available (user timeline + recent search beat scraping).
3. **YouTube channel**: this is the jargon goldmine. Get channel title/handle/description, then titles + descriptions of the ~30 most recent videos (yt-dlp works well: `yt-dlp --flat-playlist --print "%(title)s" <channel_url>`; add `--print "%(description)s"` on a few). Recurring guests, product names, and vocabulary live here. Note video count, typical length, cadence.
4. **Cross-check names**: every person/product name that will go in the dictionary must be spelling-verified against an official source (site bio, LinkedIn, channel about page). A misspelled dictionary term actively poisons transcription.

## Asset collection

Create the output folder first (see layout below), then:

- **Logos**: try in order — press/brand page downloads, header logo (`<img>`/inline SVG — prefer SVG originals), `apple-touch-icon`, `og:image`, `/favicon.ico`. Download each usable asset into `assets/` with descriptive names (`logo-primary.svg`, `favicon.png`, `og-image.jpg`). Record the source URL of every file.
- **Colors**: extract from (a) CSS custom properties on `:root`, (b) `<meta name="theme-color">`, (c) computed header/button/link colors, (d) dominant logo colors. Produce a palette of hex values with roles: primary, secondary/accent, background, text. Note where each came from.
- **Fonts** (nice-to-have): primary `font-family` stacks for headings and body.
- If the site resists scraping, take a full-page screenshot into `assets/` so colors/logo can be picked manually.

## Output

```
brand-dossier-<slug>/
  dossier.md
  assets/
    logo-primary.svg, favicon.png, og-image.jpg, screenshot-home.png, ...
```

Zip the folder (`brand-dossier-<slug>.zip`) when running in an environment where the user can't browse the filesystem (cloud/cowork); locally, leave the folder and print its path.

## dossier.md template

Every Bold-bound value sits in its own fenced code block so it can be copied in one click. Mark anything inferred rather than verified with `(inferred)`. Use this structure:

````markdown
# <Name> — Brand Dossier
_Generated <date>. Sources at bottom. Provisional sections marked — refine after transcripts._

## Facts
- Company/brand: … | Suggested slug: `<lowercase-hyphenated>`
- Site: … | LinkedIn: … | YouTube: `<handle>` (~N videos, typical length, cadence)
- Principal(s): Full Name — title/credentials, 1-line bio each
- Offer/business model: …
- Audience/ICP: …

## Bold AI Settings (paste-ready)

### Organization Context
```
<One tight paragraph, markdown allowed. Model it on this gold standard:
"AI That Works is a weekly live-build show by Vaibhav (founder of Boundary,
creator of the BAML language) and Dex (full name Dexter Horthy, founder of
HumanLayer, author of 12-Factor Agents). Each episode is a long, unscripted
session building real AI systems: agents, evals, RAG, context engineering,
structured outputs, code generation. The audience is working engineers
shipping AI features. Not beginners, not hype-chasers. They want concrete
patterns, honest tradeoffs, and what holds up in production. Produced under
Boundary, the company behind BAML."
— i.e.: what it is, who makes it (with full names + credentials), the content
shape, who the audience IS and IS NOT, what they want, parent company.>
```

### Tone
```
<3-4 comma-separated adjectives, e.g. "direct, pragmatic, dry">
```

### Domain
```
<2-4 words, e.g. "AI engineering">
```

### Language
```
<e.g. "US English, engineer-casual">
```

### Topics (comma-separated)
```
<5-10 core topics, comma-separated, no trailing comma>
```

### Account Dictionary — one term per line (multi-word phrases fine)
```
<Every proper noun likely to be SPOKEN in the videos, spelling-verified:
principals' full names; co-hosts and recurring guests; company/brand names;
product, framework, course, and program names; domain acronyms and jargon;
relevant place names. NO generic words, NO unverified spellings.>
```

## Persona (PROVISIONAL — rewrite from transcripts in Pass 2)

### Name
```
<e.g. "Ask <FirstName>" — assistant-in-their-voice framing, not impersonation>
```

### Voice & Style — draft from public writing/speaking style
```
<Best guess from site copy, video descriptions, any watchable clips.
Flag explicitly: "Draft from public materials — replace with
transcript-grounded version once videos are transcribed.">
```

### Greeting  /  Sign-off
```
<Short, on-brand; sign-off max 50 chars.>
```

## Conversation Starters (PROVISIONAL — must be retrieval-verified after ingest, Pass 3)
```
<6-8 short questions their audience would actually ask, one per line,
answerable from the content themes observed in video titles/descriptions.>
```

## Brand Kit
| Role | Hex | Source |
|------|-----|--------|
| Primary | #… | css var --… / logo |
…

Assets: `assets/<file>` — source URL each. Fonts: headings …, body ….

## Sources & Confidence
- <url> — what it provided
- Gaps/uncertain: <anything unverified, e.g. "LinkedIn unreachable — principal credentials from site bio only">
````

## Quality rules

- Never fabricate. A short verified dossier beats a padded speculative one; list gaps honestly.
- Dictionary spelling accuracy is the single highest-stakes output (it feeds transcription keyterm boosting before import). When in doubt about a spelling, leave the term out and note it as a gap.
- Prefer official sources (site, channel about, LinkedIn) over third-party articles.
- The Organization Context paragraph is the highest-leverage prose: specific names, specific content shape, explicit is/is-not audience. No marketing fluff.
