# Full Rewrite Workflow

Transform existing AI-generated text into prose that reads as 100% human-written.

## When to Use
User provides existing text (AI-generated or AI-sounding) and wants it rewritten to sound human.

## Prerequisites
- Read `references/concepts/banned-patterns.md` (the kill list)
- Read `references/concepts/master-techniques.md` (the craft arsenal)

## Steps

### Step 1: Forensic Diagnosis (Identify the Disease)

Before rewriting a single word, scan the input text and tag every AI signature present:

**Lexical scan:** Flag every word from the Tier 1 banned list (delve, leverage, tapestry, etc.)
**Structural scan:** Identify the paragraph pattern (5-paragraph essay? Hamburger paragraphs? Rule of Three?)
**Rhythmic scan:** Estimate sentence length variance. Are sentences clustered in 15-25 word range?
**Tonal scan:** Is the voice neutral-to-nowhere? Hedged? Sycophantic? Relentlessly optimistic?
**Transition scan:** Count "Furthermore," "Moreover," "Additionally," "In conclusion" occurrences
**Punctuation scan:** Count em dashes. Flag if more than 1 per 500 words
**Opening scan:** Does it start with a throat-clearing preamble?
**Closing scan:** Does it end with a Disney ending or empty summary?

Do not show this diagnosis to the user unless asked. Use it to guide rewrite priorities.

### Step 2: Structural Demolition

**Kill the preamble (Vonnegut/Leonard).** Delete the first paragraph if it's a context dump, landscape overview, or "In this article we will explore" roadmap. Find where the actual content starts. That's your new opening.

**Kill the summary ending.** If the last paragraph restarts everything that was just said, delete it. End on the last substantive point, an image, or a call to action.

**Kill the Rule of Three.** If there are 3 parallel examples, 3 bullet points, or 3 body sections of equal weight, restructure. Go to 1 vivid example, 2 paired examples, or 4-5 examples.

**Kill the Hamburger.** If every paragraph follows Topic-Support-Conclude, break the pattern. Let some paragraphs be a single sentence. Let others start with evidence, not thesis.

### Step 3: Lexical Decontamination

Run through the Tier 1 banned words. Every single one must be replaced or deleted.

Replacement rules:
- Prefer the shorter word. "Use" not "utilize." "Start" not "commence."
- Prefer the Anglo-Saxon word. "Help" not "facilitate."
- Prefer the specific word. "Slack" not "communication platform."
- If a banned word has no simple replacement, delete the entire sentence and ask what it was actually trying to say. Rewrite from the meaning, not the word.

### Step 4: Transition Purge

Delete or replace every banned transition:
- "Furthermore" and "Moreover" become nothing (just start the next sentence) or "And" or "Plus"
- "In conclusion" becomes nothing. Just conclude.
- "It is important to note" becomes nothing. If it's important, the sentence after it does the work.
- "In order to" becomes "to"
- "As such" becomes "so"

**The Klinkenborg test:** After removing a transition, read the two sentences. If the connection is obvious without the connector, leave it deleted. Trust the reader.

### Step 5: Rhythmic Surgery (Provost)

Scan sentence lengths across the piece:

1. Find clusters of 3+ sentences in the 15-25 word range. Break one into a fragment (under 5 words). Combine two into one long, flowing sentence.

2. Place a "staccato spike" (1-4 word sentence) after a long complex sentence for emphasis.

3. Place a "crescendo" (35+ word sentence with multiple clauses) after a sequence of short sentences.

4. Use one-sentence paragraphs as pattern interrupts. Drop one every 400-600 words.

5. Verify: No more than 2 consecutive sentences should be within 5 words of each other in length.

### Step 6: Abstraction Descent (Clark)

Find every abstract noun phrase and ask: What does that look like in reality?

- "The digital landscape" becomes "Instagram, TikTok, and whatever app your cousin won't shut up about"
- "Key stakeholders" becomes "the three people who actually approve the budget"
- "User experience" becomes "what happens when someone clicks the button"

Inject at least one sensory detail per 300 words:
- A smell, a texture, a sound, a temperature, a taste
- A specific brand name, a dollar amount, a time of day
- A physical gesture instead of an emotion label

### Step 7: Verb Activation (Hale)

Find every "is," "are," "was," "were," "has," "have" used as main verbs. Replace at least 50% with kinetic verbs.

- "The market is volatile" becomes "The market swings"
- "There are several challenges" becomes "Challenges stack up"
- "It was a success" becomes "It worked"

### Step 8: Voice Injection

If the user specified a target content type different from the input format (e.g., "turn this report into a LinkedIn post"), apply the structural blueprint from write-from-scratch.md Step 2 for the target type.

Based on content type, inject the appropriate voice:

**Blog/Article:** First person, opinion, mild irreverence. "I believe," "Here's what I've seen," "Frankly."
**LinkedIn:** Confessional, peer-level. Start with failure, not achievement.
**Sales Copy:** Second person ("you"), sensory empathy, problem-agitation-solution.
**Technical:** Imperative active ("Click the button"), second person, no passive.
**Email:** Conversational, reference shared context, radical honesty.
**Essay/Memoir:** Sensory specificity, irrelevant details, anti-epiphany (don't wrap in a bow).
**Social Media:** Fragments, contrarian hooks, lowercase energy, no emoji-as-decoration.

### Step 9: Em Dash Removal

Search for every em dash (—) in the text. Replace each one:
- If it introduces a definition or explanation: use a colon
- If it's a parenthetical aside: use parentheses or commas
- If it separates two independent thoughts: use a period
- If it creates dramatic pause: use a period and start a new sentence

Zero em dashes in final output.

### Step 10: Final Polish

1. Read the text as if you've never seen it. Does it flow? Does it sound like a person wrote it while drinking coffee at their kitchen table?

2. Check: Is there at least one moment of genuine surprise, humor, opinion, or vulnerability?

3. Check: Could any sentence be predicted by completing "The most likely next word is..."? If yes, rewrite it.

4. Check: Does the opening hook you in the first 10 words?

5. Check: Does the ending leave an impression, not a summary?

## Output Format

Deliver only the rewritten text. Do not explain the changes unless the user asks. Do not add a preamble like "Here's the humanized version." Just deliver the text.

If the user asks what changed, provide a brief summary of the major structural and tonal shifts.
