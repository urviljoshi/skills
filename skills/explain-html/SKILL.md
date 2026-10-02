---
name: explain-html
description: Explain something as a single self-contained, interactive HTML page - with diagrams, steppers, sliders, live examples, and animation where they help understanding. Use when the user asks for an explanation "in HTML", "as a web page", "as an interactive page", an "explorable", or a visual report, or when the subject has several parts to explore, compare, or try with different inputs.
---

# Explain with a web page

A web page can do what text cannot: let the reader change an input and see the result, step through a process, or look at one part while the others stay in view. The page is a throwaway artifact made for one explanation. Make it custom to the subject.

## 1. Plan the page before you write it

Answer these in a few lines:

- **The one thing** the reader must understand at the end.
- **The path**: 3 to 6 sections that build to it, each with one idea.
- **The interaction** for each section, if one helps. Ask: "what would the reader want to poke?" Good answers:
  - A slider or input that changes a parameter and updates a figure.
  - A stepper (next / back) through a process, with the state shown at each step.
  - A toggle between before and after, or between two alternatives.
  - Hover or click on a part to see its detail.
  - A small live example that runs in the page.

Interaction must show something about the subject. Do not add animation, tabs, or accordions only as decoration. A section with nothing to interact with is fine as text and a figure.

## 2. Build it

Technical contract:

- **One `.html` file.** Inline the CSS and JavaScript. No build step, no framework required. It must work when opened from disk with `file://`.
- **No network dependency for the content.** If you use a library from a CDN (for example D3 or KaTeX), the page must still show its main content when the request fails. Prefer plain JavaScript, SVG, and Canvas.
- **Real data.** Embed the actual numbers, code, or structures from the source. Do not use invented placeholder data unless you label it as an illustration.
- **Responsive.** It must read well on a phone width and on a wide monitor. No horizontal scroll of the page.
- **Light and dark.** Define colors as CSS variables and support `prefers-color-scheme`.
- **Accessible.** Use real buttons and inputs, labels on controls, keyboard access, sufficient contrast, and respect `prefers-reduced-motion`.

Design:

- Start with the conclusion in one or two sentences at the top. The reader who stops there still gets the answer.
- Make it look like it was designed for this subject. Choose a typeface pairing, a restrained palette with one accent color, and generous spacing. Avoid the generic look: centered everything, purple gradients, a card around each paragraph, emoji as icons.
- Text column at a comfortable reading width (about 65 characters). Figures can be wider.
- Put each control next to the figure that it changes.
- Animate only to show a change of state. Keep it short (150 to 400 ms).
- Write the prose with the `plain-writing` rules if that skill is available: short sentences, one name per thing.

## 3. Check it

1. Open the file and look at it, if the environment has a browser or a preview tool. If you have a screenshot tool, use it. Fix what you see: overflow, overlap, unreadable contrast, broken controls.
2. Use each control. Make sure that it changes what it claims to change, and that extreme values do not break the figure.
3. Check the browser console for errors if you can.
4. Check every claim and number against the source.

If you cannot open the page, say that you did not see it rendered.

## 4. Deliver

- Save it with a descriptive file name, for example `how-the-retry-queue-works.html`. Use the location that the user named, or a temporary or scratch directory if they named none. Do not put it in the project source tree unless the user asks.
- If the harness has an artifact or publish tool, use that tool and give the link.
- Otherwise give the absolute path and open the file with the system command (`start`, `open`, or `xdg-open`).
- Reply with one or two sentences: what the page shows and what to try first.
