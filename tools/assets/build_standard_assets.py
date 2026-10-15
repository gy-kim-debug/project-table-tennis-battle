"""Build the playable prototype's interchangeable pixel-art baseline.

All output is deterministic PNG. Pillow is needed only when rebuilding assets.
The source character sheets and their manifests are never overwritten.
"""

from __future__ import annotations

import json
import hashlib
from collections import deque
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
LAYOUT = json.loads((ROOT / "assets/table/layout.json").read_text())
VISUAL = json.loads((ROOT / "assets/visuals/active.json").read_text())
P = {name: "#" + value for name, value in VISUAL["palette"].items()}
TRANSPARENT = (0, 0, 0, 0)


def screen_point(x: float, depth: float, height: float = 0) -> tuple[int, int]:
    far_x, far_y = LAYOUT["far_center"]
    near_x, near_y = LAYOUT["near_center"]
    cx = far_x + (near_x - far_x) * depth
    cy = far_y + (near_y - far_y) * depth ** LAYOUT["depth_power"]
    half = LAYOUT["far_half_width"] + (LAYOUT["near_half_width"] - LAYOUT["far_half_width"]) * depth
    skew = LAYOUT["far_skew"] + (LAYOUT["near_skew"] - LAYOUT["far_skew"]) * depth
    sx, sy = LAYOUT["court_scale"]
    ox, oy = LAYOUT["court_offset"]
    px = ox + (cx + x * half) * sx
    py = oy + (cy + x * skew - height) * sy
    if LAYOUT["mirror_view"]:
        px = 360 - px
    return round(px), round(py)


def save(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path)
    print(path.relative_to(ROOT))


def build_table() -> None:
    table = Image.new("RGBA", (360, 640), TRANSPARENT)
    draw = ImageDraw.Draw(table)
    far_left, far_right = screen_point(-1, 0), screen_point(1, 0)
    near_left, near_right = screen_point(-1, 1), screen_point(1, 1)
    surface = [far_left, far_right, near_right, near_left]
    draw.polygon(surface, fill=P["court_shadow"])
    draw.polygon([near_left, near_right, (near_right[0], near_right[1] + 17), (near_left[0], near_left[1] + 17)], fill=P["court_apron"])
    for x in (-0.93, 0.93):
        lx, ly = screen_point(x, 0.94)
        draw.rectangle((lx - 3, ly + 5, lx + 2, ly + 42), fill=P["court_leg"])
    draw.polygon(surface, fill=P["court_surface"])
    draw.polygon([far_left, far_right, screen_point(1, 0.5), screen_point(-1, 0.5)], fill=P["court_far"])
    draw.polygon([screen_point(-1, 0.5), screen_point(1, 0.5), near_right, near_left], fill=P["court_near"])
    draw.polygon([screen_point(-0.72, 0.03), screen_point(-0.58, 0.03), screen_point(-0.66, 0.98), screen_point(-0.87, 0.98)], fill=P["court_stripe"])
    for a, b in ((far_left, far_right), (far_right, near_right), (near_right, near_left), (near_left, far_left)):
        draw.line((a, b), fill=P["court_line"], width=2)
    draw.line((screen_point(0, 0), screen_point(0, 1)), fill=P["court_center_line"], width=2)
    draw.line(((near_left[0], near_left[1] + 3), (near_right[0], near_right[1] + 3)), fill=P["court_apron_line"], width=3)
    save(table, ROOT / "assets/table/table_main.png")

    net = Image.new("RGBA", (360, 640), TRANSPARENT)
    draw = ImageDraw.Draw(net)
    left, right = screen_point(-1.04, LAYOUT["net_depth"]), screen_point(1.04, LAYOUT["net_depth"])
    top_left, top_right = (left[0], left[1] - 24), (right[0], right[1] - 24)
    draw.polygon([top_left, top_right, right, left], fill=P["net_back"])
    for index in range(25):
        t = index / 24
        top = (round(top_left[0] + (top_right[0] - top_left[0]) * t), round(top_left[1] + (top_right[1] - top_left[1]) * t))
        bottom = (round(left[0] + (right[0] - left[0]) * t), round(left[1] + (right[1] - left[1]) * t))
        draw.line(((top[0], top[1] + 4), (bottom[0], bottom[1] - 2)), fill=P["net_mesh"])
    for fraction in (0.28, 0.52, 0.76):
        a = (round(top_left[0] + (left[0] - top_left[0]) * fraction), round(top_left[1] + (left[1] - top_left[1]) * fraction))
        b = (round(top_right[0] + (right[0] - top_right[0]) * fraction), round(top_right[1] + (right[1] - top_right[1]) * fraction))
        draw.line((a, b), fill=P["net_mesh"])
    draw.line((top_left, top_right), fill=P["court_line"], width=2)
    draw.line((left, right), fill=P["net_bottom"], width=2)
    for top, bottom in ((top_left, left), (top_right, right)):
        draw.line(((top[0], top[1] - 5), (bottom[0], bottom[1] + 6)), fill=P["ink"], width=4)
    save(net, ROOT / "assets/table/table_net.png")
    digest = hashlib.sha256(json.dumps(LAYOUT, sort_keys=True, separators=(",", ":")).encode()).hexdigest()
    for profile_path in (ROOT / "assets/visuals/active.json", ROOT / "assets/templates/visual_profile.json"):
        profile = json.loads(profile_path.read_text())
        profile["layout_sha256"] = digest
        profile_path.write_text(json.dumps(profile, ensure_ascii=False, indent=2) + "\n")


def face_component(frame: Image.Image, role: str) -> Image.Image:
    pixels = frame.load()
    selected = set()
    for y in range(128):
        for x in range(128):
            r, g, b, a = pixels[x, y]
            if a == 0:
                continue
            if role == "player":
                good = r > 160 and g < 120 and b < 130 and r > g * 1.4
            else:
                good = b > 100 and b > r * 1.35 and b > g * 1.15
            if good:
                selected.add((x, y))
    largest: set[tuple[int, int]] = set()
    while selected:
        origin = selected.pop()
        component = {origin}
        pending = deque([origin])
        while pending:
            x, y = pending.popleft()
            for neighbor in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
                if neighbor in selected:
                    selected.remove(neighbor)
                    component.add(neighbor)
                    pending.append(neighbor)
        if len(component) > len(largest):
            largest = component
    assert len(largest) >= 50, f"missing racket face: {role}"
    mask = Image.new("L", (128, 128), 0)
    mask_pixels = mask.load()
    for x, y in largest:
        mask_pixels[x, y] = 255
    # Include the short grip between the face and the holding hand. Source
    # pixels are divided, never repainted, so the baseline recomposes exactly.
    xs = [x for x, _ in largest]
    ys = [y for _, y in largest]
    cx, cy = round(sum(xs) / len(xs)), round(sum(ys) / len(ys))
    grip_end = cx + max(-12, min(12, 64 - cx))
    ImageDraw.Draw(mask).line((cx, cy, grip_end, cy), fill=255, width=3)
    expanded = mask.filter(ImageFilter.MaxFilter(5))
    alpha = frame.getchannel("A")
    return Image.composite(expanded, mask, alpha)


def build_rackets() -> None:
    for role in ("player", "enemy"):
        folder = ROOT / "assets/characters" / role
        racket_id = f"{role}_default"
        racket_folder = ROOT / "assets/rackets" / racket_id
        for animation, count in (("idle", 4), ("swing", 6), ("miss", 4)):
            source = Image.open(folder / f"{role}_{animation}.png").convert("RGBA")
            body = Image.new("RGBA", source.size, TRANSPARENT)
            racket = Image.new("RGBA", source.size, TRANSPARENT)
            for index in range(count):
                original = source.crop((index * 128, 0, (index + 1) * 128, 128))
                mask = face_component(original, role)
                racket_frame = Image.new("RGBA", (128, 128), TRANSPARENT)
                racket_frame.paste(original, (0, 0), mask)
                body_frame = original.copy()
                body_frame.paste(TRANSPARENT, (0, 0, 128, 128), mask)
                body.paste(body_frame, (index * 128, 0))
                racket.paste(racket_frame, (index * 128, 0))
            save(body, folder / f"{role}_body_{animation}.png")
            save(racket, racket_folder / f"{role}_racket_{animation}.png")
        for layer in ("body", "racket"):
            base = (folder / "frames.tres").read_text()
            for animation in ("idle", "swing", "miss"):
                source_path = f"res://assets/characters/{role}/{role}_{animation}.png"
                replacement = (f"res://assets/characters/{role}/{role}_body_{animation}.png" if layer == "body"
                               else f"res://assets/rackets/{racket_id}/{role}_racket_{animation}.png")
                base = base.replace(source_path, replacement)
            save_text = folder / "body_back.tres" if layer == "body" else racket_folder / "frames.tres"
            save_text.parent.mkdir(parents=True, exist_ok=True)
            save_text.write_text(base)
            print(save_text.relative_to(ROOT))
        manifest_path = folder / "manifest.json"
        manifest = json.loads(manifest_path.read_text())
        manifest["racket_id"] = racket_id
        manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
        racket_manifest = {
            "schema_version": 1, "id": racket_id, "role": role,
            "frame_size": [128, 128], "contact_point": manifest["contact_point"],
            "animations": {name: manifest["animations"][name] for name in ("idle", "swing", "miss")},
            "grip_owner": "racket_layer",
        }
        racket_folder.joinpath("manifest.json").write_text(json.dumps(racket_manifest, ensure_ascii=False, indent=2) + "\n")


def build_effects() -> None:
    folder = ROOT / "assets/effects"
    marker = Image.new("RGBA", (36, 36), TRANSPARENT)
    d = ImageDraw.Draw(marker)
    d.ellipse((6, 6, 30, 30), outline=P["marker"], width=1)
    d.line((1, 18, 5, 18), fill=P["marker"])
    d.line((31, 18, 35, 18), fill=P["marker"])
    save(marker, folder / "contact_marker.png")

    for name, size, count, color in (("bounce", 32, 4, P["ball_normal"]), ("impact", 48, 6, P["ball_normal"]), ("perfect", 80, 6, P["ball_strong"])):
        sheet = Image.new("RGBA", (size * count, size), TRANSPARENT)
        for frame in range(count):
            cell = Image.new("RGBA", (size, size), TRANSPARENT)
            draw = ImageDraw.Draw(cell)
            cx = size // 2
            if name == "bounce":
                radius = 3 + frame * 2
                draw.ellipse((cx-radius, cx-radius, cx+radius, cx+radius), outline=color)
            else:
                radius = 8 + frame * (5 if name == "perfect" else 3)
                width = 4 if name == "perfect" else 2
                for dx, dy in ((1,0),(-1,0),(0,1),(0,-1),(1,1),(-1,1),(1,-1),(-1,-1)):
                    px, py = round(cx + dx * radius), round(cx + dy * radius)
                    draw.rectangle((px, py, px+width-1, py+width-1), fill=color)
                if name == "perfect":
                    ring = round(radius * 0.7)
                    draw.ellipse((cx-ring,cx-ring,cx+ring,cx+ring), outline=P["ball_normal"], width=2)
            sheet.paste(cell, (frame * size, 0))
        save(sheet, folder / f"{name}.png")
    trail = Image.new("RGBA", (8, 8), TRANSPARENT)
    ImageDraw.Draw(trail).rectangle((2,2,5,5), fill=P["ball_normal"])
    save(trail, folder / "trail.png")
    spark = Image.new("RGBA", (8, 8), TRANSPARENT)
    ImageDraw.Draw(spark).rectangle((2,2,5,5), fill=P["damage"])
    save(spark, folder / "damage_spark.png")
    confetti = Image.new("RGBA", (4, 6), TRANSPARENT)
    ImageDraw.Draw(confetti).rectangle((0,0,3,5), fill=P["ball_strong"])
    save(confetti, folder / "confetti.png")


def build_ui() -> None:
    folder = ROOT / "assets/ui"
    for name, size, border in (("pause_panel", (312,260), P["player"]), ("result_panel", (312,180), P["ball_strong"]), ("button", (32,32), P["court_line"]), ("button_pressed", (32,32), P["ball_strong"])):
        image = Image.new("RGBA", size, P["ink"])
        draw = ImageDraw.Draw(image)
        draw.rectangle((0,0,size[0]-1,size[1]-1), outline=border, width=2)
        save(image, folder / f"{name}.png")
    hp_base = Image.new("RGBA", (8,8), P["court_apron"])
    ImageDraw.Draw(hp_base).rectangle((0,0,7,7), outline=P["net_mesh"])
    save(hp_base, folder / "hp_base.png")
    for name, color in (("hp_player", P["player"]), ("hp_enemy", P["opponent"])):
        save(Image.new("RGBA", (8,8), color), folder / f"{name}.png")
    arrow = Image.new("RGBA", (9, 7), TRANSPARENT)
    arrow_draw = ImageDraw.Draw(arrow)
    for y in range(4):
        arrow_draw.line((y, y + 1, 8 - y, y + 1), fill=P["court_line"])
    save(arrow, folder / "menu_arrow.png")
    save(Image.new("RGBA", (360,110), (11,16,32,199)), folder / "hud_scrim.png")


if __name__ == "__main__":
    build_table()
    build_rackets()
    build_effects()
    build_ui()
