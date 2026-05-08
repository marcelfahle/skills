# Anti-patterns (pre-delivery checklist)

Run this before handing the keyword plan back. If any box is unchecked, the
output is not ready.

## Data integrity

- [ ] Every keyword has a `volume`, `CPC`, and `KD` populated from a
      DataForSEO response (not inferred, not "≈", not blank).
- [ ] Keywords with `volume = null` are either dropped or explicitly tagged
      `(no_data)` — never silently rewritten as 0 or "low."
- [ ] No number was rounded into a "nice" figure (e.g., a real 1,283 stays
      1,283, not "~1.3K").
- [ ] Every batch has a citation footer: endpoint, location code, language
      code, ISO timestamp.
- [ ] Raw JSON for each call is saved under `keyword-research/raw/<project>/
      <YYYY-MM-DD>/`. Re-deliveries can be reproduced.

## Intent + clustering

- [ ] Every keyword has an intent tag (informational / commercial /
      transactional / navigational / local).
- [ ] Intent was derived from the SERP for at least the head terms — not
      guessed from the keyword string.
- [ ] Keywords are grouped by parent topic. There is no flat dump.
- [ ] Brand terms (user's brand, competitor brands) are in a separate section
      from generic commercial / informational terms.
- [ ] Each cluster names the page type it implies (landing page / blog post /
      comparison page / glossary / pSEO template).

## Prioritization

- [ ] The "Top opportunities" table has 10 entries max, each with a one-line
      "Why" justifying the pick (volume × intent × KD vs DR fit).
- [ ] KD is contextualized against the user's domain bucket (new site /
      DR<30 / DR 30–60 / DR>60). A "KD 45" call without that context fails.
- [ ] Long-tail (volume < 100) is included where it's transactional or
      product-fit; not pruned just because volume is low.
- [ ] Negatives list is populated for any paid-search-related deliverable.

## ICP fit

- [ ] The ICP was actually read (Obsidian search hit + file path cited), not
      asked for again when it already existed.
- [ ] Each cluster is tied back to a persona / pain point / JTBD from the ICP
      doc in one line.
- [ ] No cluster targets an audience the ICP explicitly excludes.

## Output hygiene

- [ ] The output follows the exact shape in `SKILL.md` → "Output Shape."
- [ ] A CSV companion was emitted alongside the markdown plan, with column
      order matching the cluster tables.
- [ ] No competitor copy was pasted in (competitor data appears as
      keyword + URL + title only).
- [ ] No meta-commentary in the deliverable. The markdown file reads as a
      brief, not as a chat log.
