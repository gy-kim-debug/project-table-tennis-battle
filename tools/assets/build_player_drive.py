"""Normalize the generated forehand-drive strip into six 128px player frames."""
from pathlib import Path
import hashlib
import json

import numpy as np
from PIL import Image
from scipy import ndimage


ROOT = Path(__file__).resolve().parents[2]
SOURCE = ROOT / "assets/source/characters/player_drive_source.png"
OUTPUT = ROOT / "assets/characters/player"


def build() -> None:
    rgba = np.asarray(Image.open(SOURCE).convert("RGBA"))
    labels, _ = ndimage.label(rgba[:, :, 3] >= 128, np.ones((3, 3)))
    objects = []
    for label, slices in enumerate(ndimage.find_objects(labels), 1):
        if slices is None:
            continue
        mask = labels[slices] == label
        if int(mask.sum()) < 2000:
            continue
        ys, xs = slices
        feet_y, feet_x = np.where(mask[max(0, mask.shape[0] - 13):, :])
        foot_x = (int(feet_x.min()) + int(feet_x.max())) / 2
        objects.append((xs.start, [xs.start, ys.start, xs.stop, ys.stop], mask, rgba[slices].copy(), foot_x))
    objects.sort(key=lambda item: item[0])
    assert len(objects) == 6, f"expected six drive poses, found {len(objects)}"

    manifest_path = OUTPUT / "manifest.json"
    manifest = json.loads(manifest_path.read_text())
    pivot = manifest["pivot"]
    max_left = max(item[4] for item in objects)
    max_right = max(item[2].shape[1] - 1 - item[4] for item in objects)
    max_height = max(item[2].shape[0] - 1 for item in objects)
    scale = min(120 / (max_left + max_right), 110 / max_height)

    visible = np.concatenate([item[3][:, :, :3][item[2]] for item in objects])
    training = Image.fromarray(visible.reshape((-1, 1, 3)).astype("uint8"), "RGB")
    palette = training.quantize(colors=32, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE)
    frames = []
    records = []
    for index, (_, box, mask, pixels, foot_x) in enumerate(objects):
        pixels[:, :, 3] = np.where(mask, 255, 0).astype("uint8")
        crop = Image.fromarray(pixels, "RGBA")
        size = (round(crop.width * scale), round(crop.height * scale))
        small = crop.resize(size, Image.Resampling.NEAREST)
        alpha = small.getchannel("A")
        colored = small.convert("RGB").quantize(palette=palette, dither=Image.Dither.NONE).convert("RGBA")
        colored.putalpha(alpha)
        x = round(pivot[0] - foot_x * scale)
        y = pivot[1] - (size[1] - 1)
        assert x >= 0 and y >= 0 and x + size[0] <= 128 and y + size[1] <= 128, (index, x, y, size)
        frame = Image.new("RGBA", (128, 128))
        frame.alpha_composite(colored, (x, y))
        opaque_box = frame.getchannel("A").getbbox()
        assert opaque_box is not None and opaque_box[3] == 117 and opaque_box[0] > 0 and opaque_box[2] < 128
        frames.append(frame)
        records.append({"animation": "swing", "index": index, "source_rect": box,
                        "opaque_rect": opaque_box, "sha256": hashlib.sha256(frame.tobytes()).hexdigest()})

    contact = np.asarray(frames[3])
    assert len({frame.tobytes() for frame in frames}) == 6, "drive frames must be distinct"
    rgb = contact[:, :, :3].astype("int16")
    red = (rgb[:, :, 0] > 110) & (rgb[:, :, 0] > rgb[:, :, 1] * 1.5) & (rgb[:, :, 0] > rgb[:, :, 2] * 1.4) & (contact[:, :, 3] > 0)
    patches, _ = ndimage.label(red)
    areas = np.bincount(patches.ravel())
    areas[0] = 0
    contact_y, contact_x = np.where(patches == int(areas.argmax()))
    assert len(contact_x) > 8, "contact paddle not found"
    contact_point = [round(float(contact_x.mean())), round(float(contact_y.mean()))]

    sheet = Image.new("RGBA", (768, 128))
    for index, frame in enumerate(frames):
        sheet.alpha_composite(frame, (128 * index, 0))
    sheet.save(OUTPUT / "player_swing.png")
    enlarged = [Image.alpha_composite(Image.new("RGBA", (128, 128), (23, 33, 59, 255)), frame).convert("RGB").resize((256, 256), Image.Resampling.NEAREST) for frame in frames]
    enlarged[0].save(OUTPUT / "swing_preview.gif", save_all=True, append_images=enlarged[1:], duration=50, loop=0)
    idle = Image.open(OUTPUT / "player_idle.png").convert("RGBA")
    miss = Image.open(OUTPUT / "player_miss.png").convert("RGBA")
    previews = []
    for step in range(12):
        preview = Image.new("RGBA", (384, 128), (23, 33, 59, 255))
        preview.alpha_composite(idle.crop((step % 4 * 128, 0, (step % 4 + 1) * 128, 128)), (0, 0))
        preview.alpha_composite(frames[step % 6], (128, 0))
        preview.alpha_composite(miss.crop((step % 4 * 128, 0, (step % 4 + 1) * 128, 128)), (256, 0))
        previews.append(preview.convert("RGB"))
    previews[0].save(OUTPUT / "preview.gif", save_all=True, append_images=previews[1:], duration=130, loop=0)

    manifest["frames"] = [entry for entry in manifest["frames"] if entry["animation"] != "swing"] + records
    manifest["frames"].sort(key=lambda entry: (list(manifest["animations"]).index(entry["animation"]), entry["index"]))
    manifest["contact_point"] = contact_point
    manifest["swing_variants"]["drive"] = {"animation": "swing", "contact_frame": 3}
    manifest["swing_source"] = str(SOURCE.relative_to(ROOT))
    manifest["swing_source_size"] = [rgba.shape[1], rgba.shape[0]]
    manifest["swing_source_scale"] = scale
    manifest["validation"] = "six drive frames / binary alpha / stable foot pivot / paddle contact verified; visual review pending"
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + "\n")
    print("player drive:", len(frames), "frames; scale", round(scale, 4), "contact", contact_point)


if __name__ == "__main__":
    build()
