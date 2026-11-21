# Skills

Skills and custom agents for coding agents: Claude Code, Codex, GitHub Copilot, and any other agent that reads the `SKILL.md` format.

## Quick start

Install with **Tompachilo**, the skill installer:

```bash
curl -fsSL https://raw.githubusercontent.com/urviljoshi/skills/main/install.sh | bash
```

On Windows PowerShell: `irm https://raw.githubusercontent.com/urviljoshi/skills/main/install.ps1 | iex`

## Install

### Tompachilo installer (recommended)

```
████████╗ ██████╗ ███╗   ███╗██████╗  █████╗  ██████╗██╗  ██╗██╗██╗      ██████╗
╚══██╔══╝██╔═══██╗████╗ ████║██╔══██╗██╔══██╗██╔════╝██║  ██║██║██║     ██╔═══██╗
   ██║   ██║   ██║██╔████╔██║██████╔╝███████║██║     ███████║██║██║     ██║   ██║
   ██║   ██║   ██║██║╚██╔╝██║██╔═══╝ ██╔══██║██║     ██╔══██║██║██║     ██║   ██║
   ██║   ╚██████╔╝██║ ╚═╝ ██║██║     ██║  ██║╚██████╗██║  ██║██║███████╗╚██████╔╝
   ╚═╝    ╚═════╝ ╚═╝     ╚═╝╚═╝     ╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚══════╝ ╚═════╝
```

Tompachilo is an interactive installer. It asks which skills you want, which coding agents to install them for (Claude Code, Codex, GitHub Copilot), whether to install globally or into the current project, and which custom agents you want.

macOS, Linux, or Git Bash on Windows:

```bash
curl -fsSL https://raw.githubusercontent.com/urviljoshi/skills/main/install.sh | bash
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/urviljoshi/skills/main/install.ps1 | iex
```

Use the arrow keys to move, space to select, `a` to select all, and enter to confirm. To install without the menus (for example in CI):

```bash
curl -fsSL https://raw.githubusercontent.com/urviljoshi/skills/main/install.sh | bash -s -- --to claude,codex --skills all --yes
```

```powershell
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/urviljoshi/skills/main/install.ps1))) -To claude,codex -Skills all -Yes
```

Options: `--to` (`claude`, `codex`, `copilot`, `all`), `--skills` (names or `all`), `--agents` (names, `all`, or `none`), `--global` or `--project`, `--list`, `--ref <branch>`, `--yes`. In PowerShell the same options start with one dash and a capital letter (`-To`, `-Project`).

Where the installer puts files:

| Agent | Global | Project | Custom agents |
| --- | --- | --- | --- |
| Claude Code | `~/.claude/skills/` | `.claude/skills/` | `~/.claude/agents/` or `.claude/agents/` |
| Codex | `~/.agents/skills/` | `.agents/skills/` | Not supported |
| GitHub Copilot | `~/.copilot/skills/` | `.github/skills/` | `~/.copilot/agents/` or `.github/agents/` as `<name>.agent.md` |

### Any agent: `npx skills`

```bash
npx skills@latest add urviljoshi/skills
```

`npx skills` also asks which skills you want and which agents to install them for. To install one skill:

```bash
npx skills@latest add urviljoshi/skills --skill explain-html
```

### Claude Code: plugin

This also installs the custom agents.

```
/plugin marketplace add urviljoshi/skills
/plugin install explain@agent-workflow-packs
```

### Manual copy

Clone the repository and copy the folders that you want.

| Agent | Skills go in | Agents go in |
| --- | --- | --- |
| Claude Code | `~/.claude/skills/` or `<project>/.claude/skills/` | `~/.claude/agents/` or `<project>/.claude/agents/` |
| Codex | `~/.agents/skills/` or `<project>/.agents/skills/` | Paste the body of the agent file into your prompt or `AGENTS.md` |
| GitHub Copilot | `~/.copilot/skills/` or `<project>/.github/skills/` | `<project>/.github/agents/<name>.agent.md` |
| Other | The skills directory of your agent, or reference the `SKILL.md` from your `AGENTS.md` | Same as Codex |

Each skill is a folder. Copy the whole folder, not only `SKILL.md`: some skills have scripts and reference files.

## The `explain` pack

As models do more of the work, more of your time goes to understanding what they produced. These skills make the agent choose a better output format than a wall of text.

| Skill | What it does | Ask for it with |
| --- | --- | --- |
| [`explain`](skills/explain/SKILL.md) | Picks the best format for an explanation, then uses one of the skills below. | "Explain how the retry queue works." |
| [`plain-writing`](skills/plain-writing/SKILL.md) | Writes in the style of ASD-STE100 (Simplified Technical English): short sentences, active voice, one name per thing. Default strictness is 80%. | "Explain this in STE." / "Too wordy, make it plain." |
| [`explain-diagram`](skills/explain-diagram/SKILL.md) | Draws a diagram: chooses the type from the question and the medium (ASCII, Mermaid, SVG) from where you will read it. | "Draw the login flow." |
| [`explain-html`](skills/explain-html/SKILL.md) | Builds a single-file interactive web page with steppers, sliders, and live figures. | "Explain this module in HTML." |
| [`explain-video`](skills/explain-video/SKILL.md) | Makes a narrated 3Blue1Brown-style video with Manim. Narration uses a free local voice by default and ElevenLabs if `ELEVENLABS_API_KEY` is set. | "Make a 3b1b style video on binary search." |

Custom agents:

| Agent | What it does |
| --- | --- |
| [`video-producer`](agents/video-producer.md) | Builds an explainer video in its own context, so that render logs stay out of your main conversation. |
| [`explanation-checker`](agents/explanation-checker.md) | Read-only. Checks an explanation against its source for wrong claims and for places where a reader would get lost. |

### Requirements for `explain-video`

The other skills need nothing. The video skill needs:

- Python 3.10+ and [Manim Community](https://www.manim.community/): `pip install manim`
- ffmpeg
- One narration backend:
  - [Kokoro](https://github.com/hexgrad/kokoro) (free, local): `pip install kokoro soundfile`
  - [Piper](https://github.com/OHF-Voice/piper1-gpl) (free, local): `pip install piper-tts`, and set `PIPER_MODEL`
  - [edge-tts](https://github.com/rany2/edge-tts) (free, online, no key): `pip install edge-tts`
  - ElevenLabs (paid): set `ELEVENLABS_API_KEY`
- LaTeX, only if you want typeset math

## Repository layout

```
skills/<name>/SKILL.md      one folder per skill; optional scripts/ and references/
agents/<name>.md            custom agents (Claude Code subagent format)
.claude-plugin/             Claude Code plugin and marketplace manifests
install.sh, install.ps1     interactive installers; they find new skills and agents automatically
```

## Contributing

See [AGENTS.md](AGENTS.md) for the conventions that a new skill or agent must follow.

You do not need to change the installer scripts when you add a skill or an agent. They read `skills/*/SKILL.md` and `agents/*.md` when they run, and show each one in the menu with its `description`.

## License

[MIT](LICENSE)
