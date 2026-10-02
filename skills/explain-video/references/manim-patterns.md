# Manim patterns for narrated explainers

Written for Manim Community (`pip install manim`). Not for `manimgl`.

## Template

```python
import json
from pathlib import Path

from manim import *

AUDIO = Path("audio")
DURATIONS = json.loads((AUDIO / "durations.json").read_text())

# Fixed meanings for colors. Use the same ones in every scene.
BG = "#0e1116"
PRIMARY = BLUE_C      # the thing we follow
ACCENT = YELLOW_C     # what to look at now
MUTED = GREY_B        # context


class Segment(Scene):
    """Base class. A subclass sets `seg` and implements `play_segment`."""

    seg = ""

    def construct(self):
        self.camera.background_color = BG
        info = DURATIONS[self.seg]
        self.add_sound(str(AUDIO / info["file"]))
        self.play_segment()
        # Hold until the narration ends, plus a short breath.
        remaining = info["seconds"] - self.renderer.time
        self.wait(max(remaining, 0) + 0.3)

    def play_segment(self):
        raise NotImplementedError


class Seg01(Segment):
    seg = "01"

    def play_segment(self):
        title = Text("Binary search", font_size=64)
        self.play(Write(title), run_time=1.5)
        self.play(title.animate.scale(0.5).to_edge(UP), run_time=1)
```

Render one scene: `python -m manim -ql video.py Seg01`. A still of its last frame: add `-s`.

## Timing

- The length of the audio is the budget. Read `DURATIONS[seg]["seconds"]` and plan the `run_time` values so that their sum is a little less than the budget. The base class fills the rest with a wait.
- If the animation is longer than the audio, the next segment's voice starts late and the video feels slow. Cut animation or add a sentence.
- To hit a word, split the segment. Timing inside one audio file is a guess. Timing at a segment boundary is exact.
- For proportional timing inside a scene: `t = info["seconds"]`, then `run_time=0.4 * t`.

## Continuity between scenes

Each scene renders to its own file, so an object does not carry over. To make the join invisible:

- Build shared objects in a function (`def make_array(): ...`) and call it in each scene.
- Start scene N+1 with the object in its final state from scene N. Use `self.add(obj)`, not `self.play(Create(obj))`.

## Layout

- The frame is about 14.2 units wide and 8 units high. Keep content inside 12 by 6.5.
- Place with `next_to`, `to_edge`, `arrange`, and `VGroup`. Avoid absolute coordinates.
- Fit to the frame: `if m.width > 12: m.scale_to_fit_width(12)`.
- Text: `font_size` 36 or more for labels, 48 or more for the main words.
- No LaTeX installed: use `Text` and `MarkupText`. `MathTex`, `Tex`, and the default labels of `Axes` and `NumberLine` (`include_numbers=True`) need LaTeX.

## Motion that explains

| To show | Use |
| --- | --- |
| A becomes B | `Transform`, `ReplacementTransform`, `TransformMatchingShapes` |
| Look here | `Indicate`, `Circumscribe`, `FocusOn`, or dim the rest with `.animate.set_opacity(0.25)` |
| A value that changes | `ValueTracker` with `always_redraw` |
| A quantity that grows | `GrowFromEdge`, or animate the width of a `Rectangle` |
| Order of steps | `LaggedStart(*anims, lag_ratio=0.15)` |
| Remove what is done | `FadeOut` |

Prefer a transform to a cut. When one object changes into the next, the viewer sees the relationship.

## Common faults

- **Black video or no sound**: `add_sound` got a path that does not exist. Paths are relative to the directory where you run `manim`.
- **Text overlap**: two objects were placed with `to_edge(UP)`. Group them and `arrange(DOWN)`.
- **Scene shorter than its audio**: the last `self.wait` is missing. Use the base class.
- **Concat fails or audio drifts**: the scenes were rendered at different quality flags. Render all at the same quality, or re-encode at the join.
- **`-s` shows an empty frame**: the scene ends with a `FadeOut` of everything. Take the still before that line.
