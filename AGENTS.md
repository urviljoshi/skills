# Conventions for this repository

This repository ships skills and custom agents that must work in many coding agents, not only one.

## Skills

- One folder per skill: `skills/<name>/SKILL.md`. The folder name and the `name` in the frontmatter are the same, in lowercase with hyphens.
- Frontmatter has `name` and `description` only. Other keys are not portable across agents.
- The `description` says what the skill does and when to use it, with the phrases a user would say. Agents decide to load a skill from the description alone.
- Keep `SKILL.md` short enough to read in one pass. Move long reference material to `references/` and code to `scripts/`, and link to them from `SKILL.md`.
- Do not name tools of one specific agent in a skill body. Write "open the file if the environment permits", not the name of a tool.
- Scripts use only the standard library at import time and state their optional dependencies at the top.
- Never put a secret in a file. Read keys from the environment.

## Agents

- One file per agent: `agents/<name>.md`, with `name` and `description` in the frontmatter. `tools` is optional and restricts the agent.
- The body is the system prompt of the agent. Say what it produces, what it must not do, and what its final report contains.

## When you add a skill or an agent

1. Add it to the table in `README.md`.
2. If it belongs to a new pack, add a plugin entry to `.claude-plugin/marketplace.json`.
