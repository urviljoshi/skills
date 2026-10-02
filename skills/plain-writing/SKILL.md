---
name: plain-writing
description: Write or rewrite explanations in a controlled, plain technical style modelled on ASD-STE100 (Simplified Technical English) - short sentences, active voice, one meaning per word, one instruction per sentence. Use when the user asks for a clear, plain, simple, or readable explanation, asks for "STE", "ASD-STE100", or "simplified technical English", or says that output is too wordy, dense, or hard to read.
---

# Plain writing

ASD-STE100 is a controlled-language specification made for aerospace maintenance manuals. Its constraints remove most of what makes model output hard to read: long sentences, passive voice, synonyms for the same thing, and filler.

This skill applies the **writing rules** of that style. It does not use the official approved-word dictionary, so do not tell the user that the text conforms to ASD-STE100. Say "written in the style of ASD-STE100".

## Strictness

Default to **80%**. The full specification is harsh for normal reading. Change the level if the user asks ("full STE", "strict", "soften it", "60%").

| Level | Apply |
| --- | --- |
| 100% (strict) | All rules below, no exceptions. |
| 80% (default) | All rules, but: sentences can reach 25 words, `-ing` forms are permitted where the alternative is awkward, and normal technical vocabulary of the field is permitted. |
| 60% (soft) | The sentence, voice, and consistency rules only. Normal vocabulary and tenses. |

## Rules

### Words

- **One word, one meaning.** Use "check" only as a verb, not also as a noun.
- **One thing, one name.** If you call it "the cache" once, do not call it "the store" or "the buffer" later. Synonyms make the reader think there are two things.
- Use the short common word: "use" not "utilize", "start" not "initiate", "show" not "demonstrate".
- Keep the technical names of the subject exactly as they are (function names, product names, units). Do not simplify them.
- No noun clusters longer than three words. Write "the timeout of the retry queue", not "the retry queue timeout configuration value".
- No idioms, metaphors, or figures of speech.
- No intensifiers or hedges: "very", "really", "quite", "basically", "simply", "just".

### Sentences

- **Maximum 20 words** in an instruction. **Maximum 25 words** in a description.
- **One instruction per sentence.** Two actions join only if they occur at the same time.
- **One topic per sentence** in descriptions.
- **Active voice.** Write "the server rejects the request", not "the request is rejected". Use passive only when the agent is unknown or not important.
- **Imperative for instructions.** "Set the flag to `true`." Not "you should set" or "the flag should be set".
- Simple tenses: present, past, future. Avoid "has been doing" and "would have been".
- Keep the articles: "the", "a", "an". Do not write in telegraph style.
- Avoid `-ing` forms as verbs or nouns: "to start the server" not "starting the server". Technical names that end in `-ing` are permitted.
- Put the condition first: "If the test fails, read the log." Not "Read the log if the test fails."

### Structure

- Maximum six sentences in a paragraph. One topic per paragraph.
- Start each paragraph with the topic sentence.
- Use a numbered list for steps that occur in sequence. Use a bulleted list for items with no sequence.
- Put a warning before the step it applies to, not after. Start it with a clear command or condition: "Do not run this on production data. The command deletes the table."
- Give the result of a step when it helps the reader to know that the step worked.

### What stays the same

- The facts. Do not drop a qualification, a number, or an exception to make a sentence shorter. Split the sentence.
- Code, commands, file paths, error text, and quoted material. Keep them exact, in code formatting.

## Procedure

1. Write down what the reader must know or do. Put the most important item first.
2. Write the text with the rules for the selected level.
3. Read each sentence and do these checks:
   - Count the words. Split the sentence if it is too long.
   - Find the verb. If the voice is passive, name the agent and make it active.
   - Find each term. Make sure that it has the same name as before.
4. Remove each sentence that does not help the reader to understand or to act.

## Example

Before:

> It's worth noting that when the cache gets invalidated, which basically happens whenever a write is being processed by the storage layer, any requests that are in flight should ideally be retried, leveraging the built-in backoff mechanism.

After (80%):

> The storage layer invalidates the cache on each write. Requests in flight at that time can fail. Retry these requests. Use the built-in backoff.
