#!/usr/bin/env python3
"""Turn a narration script into one audio file per segment.

Input:  script.json  ->  [{"id": "01", "text": "..."}, ...]
Output: <out>/<id>.wav|.mp3 and <out>/durations.json
        durations.json -> {"01": {"file": "01.wav", "seconds": 4.2}, ...}

Backends, tried in this order when --backend is "auto":
  elevenlabs  needs ELEVENLABS_API_KEY (optional ELEVENLABS_VOICE_ID)
  kokoro      pip install kokoro soundfile   (local)
  piper       pip install piper-tts, PIPER_MODEL=/path/to/voice.onnx   (local)
  edge        pip install edge-tts   (free online service, no key)

Only the standard library is needed to run this file; each backend imports
its own package when it is selected.
"""

import argparse
import importlib.util
import json
import os
import shutil
import subprocess
import sys
import urllib.error
import urllib.request
import wave
from pathlib import Path

ELEVENLABS_DEFAULT_VOICE = "21m00Tcm4TlvDq8ikWAM"
ELEVENLABS_MODEL = "eleven_multilingual_v2"
KOKORO_DEFAULT_VOICE = "af_heart"
EDGE_DEFAULT_VOICE = "en-US-AndrewNeural"


def has_module(name):
    return importlib.util.find_spec(name) is not None


def available_backends():
    found = []
    if os.environ.get("ELEVENLABS_API_KEY"):
        found.append("elevenlabs")
    if has_module("kokoro") and has_module("soundfile"):
        found.append("kokoro")
    if os.environ.get("PIPER_MODEL") and (shutil.which("piper") or has_module("piper")):
        found.append("piper")
    if has_module("edge_tts"):
        found.append("edge")
    return found


def elevenlabs(segments, out, voice):
    key = os.environ["ELEVENLABS_API_KEY"]
    voice = voice or os.environ.get("ELEVENLABS_VOICE_ID") or ELEVENLABS_DEFAULT_VOICE
    url = f"https://api.elevenlabs.io/v1/text-to-speech/{voice}"
    for seg in segments:
        body = json.dumps({"text": seg["text"], "model_id": ELEVENLABS_MODEL}).encode()
        req = urllib.request.Request(
            url,
            data=body,
            headers={
                "xi-api-key": key,
                "Content-Type": "application/json",
                "Accept": "audio/mpeg",
            },
        )
        path = out / f"{seg['id']}.mp3"
        try:
            with urllib.request.urlopen(req) as resp:
                path.write_bytes(resp.read())
        except urllib.error.HTTPError as err:
            detail = err.read().decode(errors="replace")[:500]
            sys.exit(f"ElevenLabs request failed for segment {seg['id']}: {err.code} {detail}")
        yield seg["id"], path


def kokoro(segments, out, voice):
    import numpy as np
    import soundfile as sf
    from kokoro import KPipeline

    voice = voice or KOKORO_DEFAULT_VOICE
    # The first letter of a Kokoro voice name is its language code.
    pipeline = KPipeline(lang_code=voice[0])
    for seg in segments:
        chunks = [np.asarray(audio) for _, _, audio in pipeline(seg["text"], voice=voice)]
        path = out / f"{seg['id']}.wav"
        sf.write(str(path), np.concatenate(chunks), 24000)
        yield seg["id"], path


def piper(segments, out, voice):
    model = voice or os.environ["PIPER_MODEL"]
    cmd = [shutil.which("piper")] if shutil.which("piper") else [sys.executable, "-m", "piper"]
    for seg in segments:
        path = out / f"{seg['id']}.wav"
        subprocess.run(
            cmd + ["--model", model, "--output_file", str(path)],
            input=seg["text"].encode("utf-8"),
            check=True,
        )
        yield seg["id"], path


def edge(segments, out, voice):
    import asyncio

    import edge_tts

    voice = voice or EDGE_DEFAULT_VOICE
    for seg in segments:
        path = out / f"{seg['id']}.mp3"
        asyncio.run(edge_tts.Communicate(seg["text"], voice).save(str(path)))
        yield seg["id"], path


BACKENDS = {"elevenlabs": elevenlabs, "kokoro": kokoro, "piper": piper, "edge": edge}


def duration(path):
    if shutil.which("ffprobe"):
        result = subprocess.run(
            [
                "ffprobe", "-v", "error", "-show_entries", "format=duration",
                "-of", "default=noprint_wrappers=1:nokey=1", str(path),
            ],
            capture_output=True,
            text=True,
            check=True,
        )
        return float(result.stdout.strip())
    if path.suffix == ".wav":
        with wave.open(str(path), "rb") as w:
            return w.getnframes() / w.getframerate()
    sys.exit(f"ffprobe is needed to measure the length of {path.name}. Install ffmpeg.")


def load_segments(script_path):
    segments = json.loads(Path(script_path).read_text(encoding="utf-8"))
    if not isinstance(segments, list) or not segments:
        sys.exit("The script must be a non-empty JSON list of segments.")
    seen = set()
    for seg in segments:
        if not isinstance(seg, dict) or not seg.get("id") or not str(seg.get("text", "")).strip():
            sys.exit(f"Each segment needs a non-empty 'id' and 'text'. Bad segment: {seg!r}")
        if seg["id"] in seen:
            sys.exit(f"Duplicate segment id: {seg['id']}")
        seen.add(seg["id"])
    return segments


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("script", nargs="?", help="path to script.json")
    parser.add_argument("--out", default="audio", help="output directory (default: audio)")
    parser.add_argument("--backend", default="auto", choices=["auto", *BACKENDS])
    parser.add_argument("--voice", help="voice name or id for the selected backend")
    parser.add_argument("--only", nargs="+", metavar="ID", help="regenerate only these segment ids")
    parser.add_argument("--list", action="store_true", help="show the available backends and exit")
    args = parser.parse_args()

    found = available_backends()
    if args.list:
        print("Available backends:", ", ".join(found) if found else "none")
        return
    if not args.script:
        parser.error("script is required")

    backend = args.backend
    if backend == "auto":
        if not found:
            sys.exit(
                "No narration backend is available. Set ELEVENLABS_API_KEY, or install one of:\n"
                "  pip install kokoro soundfile\n"
                "  pip install piper-tts   (and set PIPER_MODEL)\n"
                "  pip install edge-tts"
            )
        backend = found[0]
    elif backend not in found:
        sys.exit(f"Backend '{backend}' is not available. Available: {', '.join(found) or 'none'}")

    segments = load_segments(args.script)
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)

    durations_path = out / "durations.json"
    durations = {}
    if args.only:
        if durations_path.exists():
            durations = json.loads(durations_path.read_text(encoding="utf-8"))
        unknown = set(args.only) - {seg["id"] for seg in segments}
        if unknown:
            sys.exit(f"Unknown segment ids: {', '.join(sorted(unknown))}")
        segments = [seg for seg in segments if seg["id"] in args.only]

    print(f"Backend: {backend}")
    for seg_id, path in BACKENDS[backend](segments, out, args.voice):
        seconds = round(duration(path), 3)
        durations[seg_id] = {"file": path.name, "seconds": seconds}
        print(f"  {seg_id}: {path.name} ({seconds:.1f}s)")

    durations_path.write_text(json.dumps(durations, indent=2), encoding="utf-8")
    total = sum(item["seconds"] for item in durations.values())
    print(f"Wrote {durations_path} (total {total:.1f}s)")


if __name__ == "__main__":
    main()
