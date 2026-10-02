---
name: explain
description: Choose the best output format for an explanation (plain controlled-language text, a diagram, an interactive web page, or a narrated explainer video) and then produce it. Use when the user asks to explain, teach, walk through, summarize for understanding, or "help me understand" a topic, a codebase, a diff, a design, or the result of work the agent just did, and has not named a format.
---

# Explain

The reader's time is the scarce resource. The agent can produce large, custom, throwaway artifacts cheaply, so choose the format that makes the subject fastest to understand, not the one that is fastest to write.

## 1. Find out what the reader needs

Work these out from the conversation. Ask only if you cannot tell.

- **Who reads it**: the user now, or other people later?
- **What they know already**: do not re-explain it.
- **What they do after**: decide, review, fix, learn, or present?

## 2. Choose the format

Use the lowest row that fits. Higher rows cost more of the agent's time; lower rows cost more of the reader's.

| The subject is mostly... | Format | Skill |
| --- | --- | --- |
| A short answer, a procedure, or a set of facts | Plain text | `plain-writing` |
| Structure, flow, sequence, or relationships between parts | Diagram | `explain-diagram` |
| Something with several parts to explore, compare, or try with different inputs | Interactive web page | `explain-html` |
| A concept that builds step by step, where motion shows the idea (math, algorithms, how a system changes over time) | Narrated video | `explain-video` |

Rules for the choice:

- If the user named a format, use that format. Do not argue.
- A quick factual question gets plain text. Do not build a web page to answer "which port does this use?".
- If you cannot decide between two rows, choose the cheaper one and offer the other in one line at the end.
- Formats combine. A web page can contain diagrams. A video starts from a plain-text script. Plain text can sit next to a diagram.
- A video takes minutes and needs local tools. Say this before you start if the user did not ask for one.

## 3. Produce it

Load the skill for the chosen format and follow it. If that skill is not installed, apply the same intent with what you know and tell the user which skill would improve the result.

## 4. Check before you deliver

For every format:

- **Correct**: every claim matches the source (the code, the data, the document). An attractive wrong explanation is worse than none.
- **Leads with the point**: the main idea is in the first sentence, the first frame, or the top of the page.
- **No padding**: remove anything the reader does not need for their next action.
- **Reachable**: give the file path or link, and open the file if the environment lets you.
