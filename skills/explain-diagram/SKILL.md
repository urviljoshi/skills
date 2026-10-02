---
name: explain-diagram
description: Explain something with a diagram instead of prose - flowchart, sequence, architecture, state machine, data model, timeline, or a custom SVG figure. Use when the user asks for a diagram, chart, picture, visual, or "draw this", or when the subject is structure, flow, order of events, or relationships between parts that prose would describe badly.
---

# Explain with a diagram

A diagram is faster to read than prose when the subject has shape: things connected to things, steps in an order, states with transitions. It is slower when the subject is a list of facts. Draw only when there is a shape to show.

## 1. Find the one question

Each diagram answers one question. Write the question down before you draw. Put it, or its answer, in the title.

- "What calls what when a user logs in?" is a diagram.
- "Everything about the auth system" is five diagrams, or a web page (see `explain-html`).

## 2. Choose the type from the question

| Question | Type |
| --- | --- |
| What happens, in what order, between which parts? | Sequence diagram |
| What are the steps and decisions? | Flowchart |
| What are the parts and how do they connect? | Architecture / box-and-arrow |
| What states can it be in and what moves it between them? | State diagram |
| What data exists and how is it related? | Entity-relationship diagram |
| What happened when? | Timeline or Gantt |
| What contains what? | Tree or nested boxes |
| How does a quantity change or compare? | A chart, not a diagram. Plot the data. |
| A mechanism with geometry (memory layout, a tensor shape, a network packet) | Custom SVG figure |

## 3. Choose the medium from where it will be read

| Reader sees it in... | Use |
| --- | --- |
| A terminal with no rendering | ASCII / box-drawing characters, in a code block, at most 80 columns |
| Markdown that renders Mermaid (GitHub, many IDEs, docs sites) | A `mermaid` code block |
| A browser, or you can write and open a file | A standalone `.svg` or `.html` file with inline SVG. Best quality and full control of layout. |
| A harness with an artifact or preview tool | That tool, with inline SVG |

If you do not know, write a standalone `.html` file with inline SVG, give the path, and open it if you can. Also keep a Mermaid or ASCII version in the reply so there is something to see immediately.

## 4. Draw it

- **Get the facts from the source.** Read the code or the document. Do not draw the architecture you expect; draw the one that is there.
- **At most about 12 nodes.** If you have more, group them or split the diagram.
- **Label every arrow** with what moves or what happens: "POST /login", "emits `order.created`", "on timeout". An unlabeled arrow says only "related".
- **One direction of flow**: left to right, or top to bottom. Not both.
- **Same shape and color means same kind of thing.** Use color for one distinction only (for example: ours and third-party), and add a legend if it is not obvious.
- **Names from the source**: the real service, function, table, and file names. The reader will search for them.
- **Mark the interesting part.** If the diagram exists to show a bug, a bottleneck, or a change, highlight that node or edge.
- Text must be readable without zoom. No label on top of a line or another label.
- For SVG: set a `viewBox`, use `currentColor` or CSS variables so it works on light and dark backgrounds, and use system fonts.

## 5. Check and deliver

1. Trace each arrow back to the source. Remove any that you cannot confirm.
2. If you can render it, render it and look at the result. Mermaid syntax errors and overlapping SVG labels are common, and you find them only when you look.
3. Add one or two sentences below the diagram: what to look at first, and the conclusion. Do not repeat the diagram in prose.
4. Give the file path. Open the file if the environment permits.
