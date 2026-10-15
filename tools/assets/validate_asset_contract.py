"""Validate the v1 asset contract before importing new art into Godot.

Usage: python3 tools/assets/validate_asset_contract.py
       python3 tools/assets/validate_asset_contract.py --character-dir assets/characters/new_player
       python3 tools/assets/validate_asset_contract.py --profile assets/visuals/new_theme.json
"""
from __future__ import annotations

import argparse
import json
import re
import sys
import wave
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[2]
REQUIRED_PALETTE = {
    "ink", "court_shadow", "court_apron", "court_leg", "court_surface", "court_far",
    "court_near", "court_stripe", "court_line", "court_center_line", "court_apron_line",
    "net_back", "net_mesh", "net_bottom", "marker", "ball_normal", "ball_strong",
    "player", "opponent", "skin", "racket_handle", "damage", "hud_scrim",
}
REQUIRED_CUES = {"swing", "good", "perfect", "miss", "bounce", "damage", "smash", "victory", "defeat"}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def local_path(value: str) -> Path:
    require(value.startswith("res://"), f"Godot path must start with res://: {value}")
    path = (ROOT / value[6:]).resolve()
    require(path.is_relative_to(ROOT) and path.is_file(), f"missing project asset: {value}")
    return path


def json_file(path: Path) -> dict:
    data = json.loads(path.read_text(encoding="utf-8"))
    require(isinstance(data, dict), f"JSON object expected: {path}")
    return data


def check_visual_profile(path: Path) -> None:
    profile = json_file(path)
    require(profile.get("schema_version") == 1 and profile.get("id"), "visual profile needs schema_version=1 and id")
    for key, size, transparent in (("background", (360, 640), False), ("ball", (12, 12), True), ("shadow", (16, 6), True)):
        with Image.open(local_path(profile[key])) as image:
            require(image.size == size, f"{key} must be {size}: {image.size}")
            alpha = image.convert("RGBA").getchannel("A")
            low, high = alpha.getextrema()
            require(high == 255 and (low < 255 if transparent else low == 255), f"{key} alpha mode does not match the contract")
    palette = profile["palette"]
    require(isinstance(palette, dict) and REQUIRED_PALETTE <= palette.keys(), "visual palette is missing required color slots")
    for name, value in palette.items():
        require(isinstance(value, str) and re.fullmatch(r"[0-9a-fA-F]{6}([0-9a-fA-F]{2})?", value) is not None,
                f"invalid color {name}: {value}")
    print(f"PASS visual profile: {profile['id']}")


def check_audio_profile(path: Path) -> None:
    profile = json_file(path)
    require(profile.get("schema_version") == 1 and profile.get("id"), "audio profile needs schema_version=1 and id")
    cues = profile["cues"]
    require(isinstance(cues, dict) and REQUIRED_CUES <= cues.keys(), "audio profile is missing required cues")
    for name, path_string in cues.items():
        with wave.open(str(local_path(path_string)), "rb") as stream:
            require(stream.getnchannels() == 1 and stream.getsampwidth() == 2 and stream.getframerate() == 22050 and stream.getnframes() > 0,
                    f"{name}: expected nonempty mono 22050 Hz 16-bit PCM WAV")
    print(f"PASS audio profile: {profile['id']} ({len(cues)} cues)")


def check_character(folder: Path, expected_role: str | None = None) -> None:
    manifest = json_file(folder / "manifest.json")
    character_id = folder.name
    role = manifest.get("role")
    require(role in ("player", "enemy") and (expected_role is None or role == expected_role), f"{character_id}: wrong camera role")
    require(manifest.get("frame_size") == [128, 128], f"{character_id}: frames must be 128x128")
    pivot = manifest["pivot"]
    contact = manifest["contact_point"]
    require(all(isinstance(v, int) and 0 <= v < 128 for v in pivot + contact), f"{character_id}: pivot/contact out of cell")
    require(pivot[1] == 116, f"{character_id}: foot baseline must be y=116")
    animations = manifest["animations"]
    require({"idle", "swing", "miss"} <= animations.keys(), f"{character_id}: idle/swing/miss required")
    frames_resource = (folder / "frames.tres").read_text(encoding="utf-8")
    for name, timing in animations.items():
        count = timing["count"]
        require(isinstance(count, int) and count > 0 and timing["fps"] > 0, f"{character_id}/{name}: invalid timing")
        require(f'"name": &"{name}"' in frames_resource, f"{character_id}/{name}: missing SpriteFrames animation")
        with Image.open(folder / f"{character_id}_{name}.png") as sheet:
            require(sheet.size == (128 * count, 128), f"{character_id}/{name}: wrong sheet size")
            rgba = sheet.convert("RGBA")
            for index in range(count):
                frame = rgba.crop((index * 128, 0, (index + 1) * 128, 128))
                alpha = frame.getchannel("A")
                box = alpha.getbbox()
                require(box is not None and box[0] > 0 and box[2] < 128 and box[3] == 117,
                        f"{character_id}/{name}/{index}: cut off or inconsistent feet")
                require(not any(alpha.histogram()[1:255]), f"{character_id}/{name}/{index}: nonbinary alpha")
    contact_index = manifest["contact_frame"]
    require(0 <= contact_index < animations["swing"]["count"], f"{character_id}: contact frame out of range")
    with Image.open(folder / f"{character_id}_swing.png") as sheet:
        point = sheet.convert("RGBA").getpixel((contact_index * 128 + contact[0], contact[1]))
        require(point[3] == 255, f"{character_id}: contact point misses racket art")
    for pose, spec in manifest.get("swing_variants", {}).items():
        animation = spec["animation"]
        require(pose and animation in animations, f"{character_id}: unknown swing animation for {pose}")
        require(0 <= spec["contact_frame"] < animations[animation]["count"], f"{character_id}: invalid contact frame for {pose}")
        with Image.open(folder / f"{character_id}_{animation}.png") as sheet:
            pixel = sheet.convert("RGBA").getpixel((spec["contact_frame"] * 128 + contact[0], contact[1]))
            require(pixel[3] == 255, f"{character_id}/{pose}: global racket contact misses the pose")
    print(f"PASS character: {character_id} ({role}, {len(animations)} animations)")


def resource_value(source: str, key: str) -> str:
    match = re.search(rf"^{re.escape(key)}\s*=\s*(.+)$", source, re.MULTILINE)
    require(match is not None, f"resource field missing: {key}")
    return match.group(1).strip()


def check_catalog(path: Path) -> None:
    catalog = json_file(path)
    require(catalog.get("schema_version") == 1, "catalog schema_version must be 1")
    patterns = catalog["patterns"]
    difficulties = catalog["difficulties"]
    require(patterns and difficulties and len(patterns) == len(set(patterns)), "catalog needs unique patterns and difficulties")
    pattern_ids = set()
    for path_string in patterns:
        source = local_path(path_string).read_text(encoding="utf-8")
        pattern_id = json.loads(resource_value(source, "pattern_id"))
        require(pattern_id not in pattern_ids, f"duplicate pattern ID: {pattern_id}")
        pattern_ids.add(pattern_id)
        for field in ("start_point", "hit_point"):
            match = re.fullmatch(r"Vector3\(([-\d.]+), ([-\d.]+), ([-\d.]+)\)", resource_value(source, field))
            require(match is not None, f"{pattern_id}: invalid {field}")
            x, depth, height = map(float, match.groups())
            require(-1 <= x <= 1 and depth in (0, 1) and height >= 0, f"{pattern_id}: {field} is outside logical court")
        for field in ("incoming_seconds", "return_seconds"):
            require(float(resource_value(source, field)) > 0, f"{pattern_id}: nonpositive {field}")
    difficulty_ids = set()
    for path_string in difficulties:
        source = local_path(path_string).read_text(encoding="utf-8")
        difficulty_id = json.loads(resource_value(source, "difficulty_id"))
        require(difficulty_id not in difficulty_ids, f"duplicate difficulty ID: {difficulty_id}")
        difficulty_ids.add(difficulty_id)
        match = re.fullmatch(r"PackedFloat32Array\(([^)]*)\)", resource_value(source, "pattern_weights"))
        require(match is not None, f"{difficulty_id}: invalid pattern weights")
        weights = [float(value.strip()) for value in match.group(1).split(",")]
        require(len(weights) == len(patterns) and all(weight >= 0 for weight in weights) and sum(weights) > 0,
                f"{difficulty_id}: one weight per catalog pattern is required")
    print(f"PASS catalog: {len(patterns)} trajectories, {len(difficulties)} difficulties")


def check_layout(path: Path) -> None:
    layout = json_file(path)
    require(isinstance(layout.get("mirror_view"), bool), "layout mirror_view must be boolean")
    for key in ("far_center", "near_center", "court_scale", "court_offset"):
        require(isinstance(layout.get(key), list) and len(layout[key]) == 2, f"layout {key} must have two numbers")
    require(0 < layout["net_depth"] < 1 and layout["player_scale"] > 0 and layout["enemy_scale"] > 0,
            "layout depth or character scales invalid")
    print("PASS court layout: 360x640 shared projection")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--character-dir", type=Path, help="validate an extra character folder")
    parser.add_argument("--profile", type=Path, default=ROOT / "assets/visuals/active.json")
    parser.add_argument("--audio-profile", type=Path, default=ROOT / "assets/audio/active.json")
    args = parser.parse_args()
    layout = json_file(ROOT / "assets/table/layout.json")
    check_layout(ROOT / "assets/table/layout.json")
    check_visual_profile(args.profile)
    check_audio_profile(args.audio_profile)
    for key, role in (("player_character", "player"), ("enemy_character", "enemy")):
        check_character(ROOT / "assets/characters" / layout[key], role)
    if args.character_dir:
        check_character(args.character_dir)
    check_catalog(ROOT / "resources/catalog.json")
    print("ASSET CONTRACT PASS")


if __name__ == "__main__":
    try:
        main()
    except (KeyError, OSError, TypeError, ValueError) as error:
        print(f"ASSET CONTRACT FAIL: {error}", file=sys.stderr)
        sys.exit(1)
