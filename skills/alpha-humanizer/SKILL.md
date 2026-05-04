---
name: alpha-humanizer
description: Transform AI-generated content into prose that reads as 100% human-written. Use when the user wants to "humanize" text, make AI content undetectable, rewrite content to sound human, bypass AI detectors, remove the "AI voice," write with authentic human voice, or produce content that passes as organic human writing. Also triggers on "rewrite this to sound human," "make this not sound like AI," "humanize this," "remove AI patterns," "write like a real person," or any request to eliminate synthetic writing patterns. Handles blog posts, LinkedIn posts, sales copy, emails, essays, technical docs, social media, landing pages, product descriptions, and thought leadership. Does NOT just swap words — it restructures the cognitive architecture of the text.
---

# Alpha Humanizer

Most "humanization" fails because it treats AI writing like a vocabulary problem. Swap "delve" for "explore," done. That's cosmetic surgery on a corpse.

Real humanization is cognitive reconstruction. AI text fails not because of word choice — it fails because it thinks in probabilities, not intentions. It writes from nowhere, to no one, about nothing specific. This skill attacks the root: the structural, rhythmic, tonal, and epistemic signatures that make text register as synthetic to both human readers and detection algorithms.

The skill operationalizes techniques from Gary Provost (sentence music), Roy Peter Clark (ladder of abstraction), Verlyn Klinkenborg (implication over explanation), William Zinsser (clarity and first-person warmth), George Orwell (anti-jargon), Elmore Leonard (cutting hooptedoodle), Ursula K. Le Guin (crowding and leaping), Constance Hale (kinetic verbs), Francine Prose (word-level scrutiny), and Kurt Vonnegut (killing the preamble).

## Mode Selection

Determine mode from user input. If ambiguous, default to Mode A if text is provided, Mode B if not.

**Mode A: Full Rewrite** — User pastes or uploads text to humanize. Indicators: "rewrite this," "humanize this," "make this sound human," or any text block provided with a humanization request. If user also specifies a target content type different from the input (e.g., "rewrite this as a LinkedIn post"), apply Mode A workflow but use the structural blueprint from Mode B Step 2 for the target content type.
→ Read `references/workflows/full-rewrite.md`

**Mode B: Write Human from Scratch** — No existing text provided. User wants new content created. Indicators: "write me a," "create a," "draft a," or topic-only requests.
→ Read `references/workflows/write-from-scratch.md`

**Mode C: Quick Strip** — User explicitly signals speed. Indicators: "quick edit," "just clean it up," "fast pass," "5 minute fix."
→ Read `references/workflows/quick-strip.md`

For ALL modes, before generating ANY text:
1. Read `references/concepts/banned-patterns.md` — the forensic kill list
2. Read `references/concepts/master-techniques.md` — the craft arsenal

Before delivering ANY output:
→ Read `references/anti-patterns.md` and verify output violates NONE

If unsure about output quality for a specific content type:
→ Read `references/examples/before-after.md` for calibration

## Hard Constraints (Never Violate)

1. Never use ANY word or phrase from the Banned Lexicon in `references/concepts/banned-patterns.md`
2. Never use em dashes (—). Use periods, commas, colons, or semicolons instead
3. Never start with "In today's...", "In the ever-evolving...", "In the realm of..."
4. Never use the Rule of Three for examples (use 1, 2, 4, or 5 — never 3)
5. Never end with "In conclusion," "Ultimately," or "At the end of the day"
6. Never produce sentences all within the 15-25 word range. Mix 3-word fragments with 35+ word complex sentences
7. Never use participial clause chains ("Doing X, he did Y")
8. Never hedge with "It is important to note" or "It is worth mentioning"
9. Never write from "the view from nowhere." Every piece needs a point of view, an opinion, a stake
10. Never produce a paragraph that follows Topic Sentence → Support → Summary structure for every paragraph

## Soft Constraints (Follow Unless User Overrides)

1. Default to contractions (can't, won't, doesn't) over formal equivalents
2. Use first person ("I," "we") when the content type allows it
3. Prefer Anglo-Saxon root words over Latinate (use > utilize, help > facilitate, start > commence)
4. Sentence length standard deviation must exceed 10 words
5. At least one sentence per 200 words should be under 5 words
6. At least one sentence per 200 words should exceed 30 words
7. Include at least one concrete sensory detail per 300 words
8. Break the fourth wall at least once per 500 words in casual content

## Reference File Index

- `references/concepts/banned-patterns.md` — Complete forensic kill list of AI vocabulary, syntax, and structural patterns. **Load before ALL writing.**
- `references/concepts/master-techniques.md` — The 10-master craft arsenal with specific techniques. **Load before ALL writing.**
- `references/workflows/full-rewrite.md` — Step-by-step protocol for transforming existing AI text. **Load when user provides text to humanize.**
- `references/workflows/write-from-scratch.md` — Protocol for generating new human-sounding content. **Load when user wants new content created.**
- `references/workflows/quick-strip.md` — 5-minute emergency edit protocol. **Load when user needs fast results.**
- `references/examples/before-after.md` — Annotated rewrite demonstrations across content types. **Load for output calibration.**
- `references/anti-patterns.md` — Verification checklist for final output. **Load before delivery.**
