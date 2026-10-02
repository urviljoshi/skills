---
name: explain-video
description: Create a narrated, animated explainer video on any topic in the style of 3Blue1Brown, with Manim for the animation and text-to-speech for the narration (free local voices by default, ElevenLabs when an API key is set). Use when the user asks for an explainer video, a "3b1b style" video, an animated explanation, a narrated walkthrough, or a video about a concept, an algorithm, a paper, or a piece of code.
---

# Explain with a video

The output is one `.mp4` file: animation made with code, with spoken narration, custom to one topic. A good target is 1 to 4 minutes.

A video costs minutes of render time and needs local tools. If the user did not ask for a video, confirm before you start.

## 1. Check the tools

Run these checks. Install what is missing only after the user agrees.

| Need | Check | Install |
| --- | --- | --- |
| Python 3.10+ | `python --version` | - |
| Manim Community | `python -m manim --version` | `pip install manim` |
| ffmpeg and ffprobe | `ffmpeg -version` | system package manager |
| LaTeX (only for `MathTex` / `Tex`) | `latex --version` | Optional. Without it, use `Text` and `MarkupText` only. |
| A narration backend | see below | see below |

Narration backends. `scripts/narrate.py` selects the first one that is available, in this order:

1. **ElevenLabs** - used only if `ELEVENLABS_API_KEY` is set. Best quality. Paid. Sends the script text to an external service.
2. **Kokoro** - `pip install kokoro soundfile`. Free, runs locally, good quality. Downloads a model on first use.
3. **Piper** - `pip install piper-tts`, and set `PIPER_MODEL` to a downloaded `.onnx` voice. Free, local, fast.
4. **edge-tts** - `pip install edge-tts`. Free, no key, but it sends the text to a Microsoft online service.

Never write an API key into a file. Read it from the environment. If the user gives a key in the chat, set it as an environment variable for the command only.

If no backend is available and the user does not want to install one, make a silent video with on-screen captions and say so.

## 2. Write the script first

The script is the video. Write it before any animation code.

1. State **the one idea** in one sentence.
2. Find **the visual**: the picture that makes the idea obvious when it moves. If there is no such picture, a video is the wrong format. Use `explain-html` or `explain-diagram`.
3. Write 4 to 10 **segments**. Each segment has:
   - `id`: `01`, `02`, ...
   - `text`: the narration. Spoken language, short sentences, 1 to 4 sentences. No symbols that cannot be read aloud. Write "x squared", not "x^2".
   - `visual`: what the viewer sees while they hear it.
4. Structure: a question or a surprising fact first, then build from a concrete example to the general idea, one new thing per segment, and end with the one idea stated plainly.
5. Narration and picture must say the same thing at the same time. Do not show a full equation while the voice talks about its first term.

Save the script as `script.json`:

```json
[
  {"id": "01", "text": "Why does binary search need only twenty steps to find one item in a million?", "visual": "A long row of a million dots, compressed. One dot is highlighted."},
  {"id": "02", "text": "Start in the middle. One comparison removes half of the row.", "visual": "A pointer drops on the middle. The left half fades out."}
]
```

For a video longer than about a minute, show the script to the user before you render. A change to the script is cheap now and expensive later.

## 3. Generate the narration

```bash
python <skill-dir>/scripts/narrate.py script.json --out audio
```

This writes `audio/<id>.wav` or `.mp3` for each segment and `audio/durations.json` with the length of each file in seconds. The animation takes its timing from these lengths. Generate audio before you write the scenes.

Options: `--backend elevenlabs|kokoro|piper|edge|auto`, `--voice <name or id>`, `--list` to show which backends are available.

## 4. Write the animation

One file, `video.py`, with one `Scene` class per segment. See `references/manim-patterns.md` for a working template and the patterns that keep audio and animation in sync.

Rules:

- Each scene loads its duration from `audio/durations.json`, calls `self.add_sound(...)` first, and ends with a `self.wait(...)` for the time that remains. The scene must never be shorter than its audio.
- 3Blue1Brown style: dark background, a few saturated colors with fixed meanings, objects that transform into each other and are not replaced by cuts, little text on screen.
- Keep one object on screen across segments where the script continues the same example. Continuity is what makes it feel like one explanation.
- Text on screen: a few words, large. The voice carries the sentences.
- Keep everything inside the frame. Check with a still image before you render video.

## 5. Render, check, and join

1. **Check each scene as a still image first.** It is fast and it finds most layout faults.
   ```bash
   python -m manim -ql -s video.py Seg01
   ```
   Look at the image. Fix overlap, text outside the frame, and unreadable sizes.
2. Render all scenes at low quality and join them. Watch for timing problems.
   ```bash
   python -m manim -ql video.py Seg01 Seg02 Seg03
   ```
3. Render at final quality (`-qh` is 1080p at 60 fps; `-qm` is 720p at 30 fps and is much faster).
4. Join the scenes in order with ffmpeg:
   ```bash
   # list.txt has one line per scene: file 'media/videos/video/1080p60/Seg01.mp4'
   ffmpeg -f concat -safe 0 -i list.txt -c copy explainer.mp4
   ```
   If the result has audio that drifts or drops, re-encode in place of `-c copy`: `-c:v libx264 -c:a aac`.
5. Confirm the result: `ffprobe explainer.mp4` must show one video stream and one audio stream, and a duration near the sum in `durations.json`.

## 6. Deliver

- Give the absolute path of the `.mp4`, its length, and which narration backend made the voice.
- Open the file with the system command if the environment permits.
- Say what you could not check. You cannot hear the audio, and you see the video only as still frames. Ask the user to tell you where the timing or the voice is wrong.
- Keep `script.json`, `video.py`, and `audio/` next to the video so that a change needs only a new render of the affected scene.
