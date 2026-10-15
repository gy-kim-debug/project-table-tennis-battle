"""Split the active character art into joint-owned, lossless pixel layers."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
EMPTY = (0, 0, 0, 0)

# Coordinates are in the character's 128x128 cell. They are editable per pose.
# Shoulder, elbow and wrist follow the existing artwork, rather than the court.
JOINTS = {
    "player": {
        "idle": [[61, 45, 69, 55, 78, 62]] * 4,
        "swing": [[60, 44, 67, 54, 78, 60], [62, 46, 72, 58, 84, 72],
                  [67, 45, 82, 48, 98, 55], [67, 43, 86, 42, 106, 41],
                  [65, 44, 76, 31, 76, 19], [61, 45, 70, 54, 79, 61]],
        "miss": [[61, 45, 69, 55, 78, 62]] * 4,
    },
    "enemy": {
        "idle": [[67, 53, 56, 61, 47, 68]] * 4,
        "swing": [[68, 54, 57, 63, 46, 71], [68, 54, 57, 55, 45, 53],
                  [69, 53, 58, 59, 46, 64], [68, 53, 55, 54, 43, 55],
                  [70, 53, 59, 41, 53, 31], [67, 53, 56, 61, 46, 70]],
        "miss": [[67, 53, 56, 61, 47, 68]] * 4,
    },
}


def split_frame(frame: Image.Image, points: list[int]) -> dict[str, Image.Image]:
    shoulder, elbow, wrist = [tuple(points[i:i + 2]) for i in (0, 2, 4)]
    masks = {}
    for name, a, b, width in (("upper_arm", shoulder, elbow, 13),
                               ("forearm", elbow, wrist, 11),
                               ("hand", wrist, wrist, 9)):
        mask = Image.new("L", (128, 128), 0)
        draw = ImageDraw.Draw(mask)
        draw.line((*a, *b), fill=255, width=width)
        radius = width // 2
        draw.ellipse((b[0] - radius, b[1] - radius, b[0] + radius, b[1] + radius), fill=255)
        masks[name] = mask
    result = {name: Image.new("RGBA", (128, 128), EMPTY) for name in ("torso", *masks)}
    # Distal pixels own shared joint boundaries; every source pixel belongs to
    # exactly one layer, so the unrotated pose reproduces the original art.
    for y in range(128):
        for x in range(128):
            pixel = frame.getpixel((x, y))
            if not pixel[3]:
                continue
            owner = "torso"
            for name in ("upper_arm", "forearm", "hand"):
                if masks[name].getpixel((x, y)):
                    owner = name
            result[owner].putpixel((x, y), pixel)
    return result


def main() -> None:
    for role, animations in JOINTS.items():
        folder = ROOT / "assets/characters" / role
        rig = {"schema_version": 1, "frame_size": [128, 128], "joints": {},
               "pose_offsets_deg": {"swing": [[-3, 2, 1], [-1, 3, 1], [1, -2, 0],
                                               [0, 0, 0], [3, -2, -1], [1, 1, 0]]}}
        base_resource = (folder / "body_back.tres").read_text()
        for animation, frames in animations.items():
            rig["joints"][animation] = [dict(zip(("shoulder", "elbow", "wrist"),
                                                   [point[i:i + 2] for i in (0, 2, 4)])) for point in frames]
            source = Image.open(folder / f"{role}_body_{animation}.png").convert("RGBA")
            output = {name: Image.new("RGBA", source.size, EMPTY)
                      for name in ("torso", "upper_arm", "forearm", "hand")}
            for index, points in enumerate(frames):
                frame = source.crop((index * 128, 0, (index + 1) * 128, 128))
                layers = split_frame(frame, points)
                for name, layer in layers.items():
                    output[name].paste(layer, (index * 128, 0))
            for name, sheet in output.items():
                sheet.save(folder / f"{role}_{name}_{animation}.png")
        for name in ("torso", "upper_arm", "forearm", "hand"):
            resource = base_resource
            for animation in animations:
                resource = resource.replace(f"{role}_body_{animation}.png", f"{role}_{name}_{animation}.png")
            (folder / f"{name}.tres").write_text(resource)
        (folder / "rig.json").write_text(json.dumps(rig, indent=2) + "\n")
        print("Built joint layers:", role)


if __name__ == "__main__":
    main()
