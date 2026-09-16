"""Builds the side-view rig from parts drawn one per image (idea/part_*.png):
each part is trimmed, scaled onto a common figure canvas, covered by a small
triangle mesh and skinned to the bones. The arm and leg are drawn once and
used for both the near and the far side. Joint positions were read off a
100 px grid over each 1024x1536 drawing.

Writes assets/companion/rig/side.json and the layer images, and a preview of
the rest pose with the bones to build/rig_preview.png."""
import json
import os

import numpy as np
from PIL import Image, ImageDraw

SP = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SP)
IDEA = f"{ROOT}/idea"
OUT = f"{ROOT}/assets/companion/rig"

W, H = 520, 1460
FLOOR = 1448

# Part name -> (anchor in the drawing, anchor on the canvas, sx, sy).
# The anchor is the point of the drawing that lands on the given canvas point.
PARTS = {
    "torso": ((541, 1249), (300, 576), 0.315, 0.315),
    "skirt": ((512, 240), (290, 536), 0.32, 0.344),
    "head": ((540, 1250), (290, 292), 0.24, 0.24),
    "hair_back": ((430, 350), (201, 140), 0.28, 0.37),
    "arm": ((490, 150), (257, 331), 0.40, 0.40),
    # The leg is three pieces from the paper-doll kit drawing, each one
    # rigid on its bone, the round joint ends overlapping.
    "thigh": ((152, 72), (318, 636), 0.47, 0.534),
    "shin": ((560, 190), (352, 1014), 0.50, 0.286),
    "shoe": ((820, 1030), (352, 1314), 0.48, 0.48),
    # The head seen from the front, cut from the front-view drawing, for
    # the swimmer turning to breathe.
    "head_front": ((67, 80), (290, 292), 3.1, 3.1),
}
FRONT_SRC = f"{ROOT}/assets/companion/stand_front.png"
KIT_SRC = f"{IDEA}/part_leg_kit.png"
# Where each piece sits in the kit drawing, and the knee the thigh piece is
# cut round at (it was drawn down to the ankle).
# The shoe is taken from its collar down, without the hinge tab drawn
# above it, and drawn over the shin so the ankle end sits inside it.
KIT_BOX = {"thigh": (20, 10, 360, 900), "shin": (405, 130, 675, 1310), "shoe": (700, 1062, 1125, 1330)}
KIT_KNEE = ((215, 780), 108)
# The hinge rivet the kit drew at the bottom of the shin sits at the ankle,
# above the shoe; it is painted over with the sock.
KIT_SHIN_RIVET = ((560, 1240), 52)
FRONT_BOX = (22, 0, 112, 88)
FRONT_FADE = 12
# Where the far copies sit relative to the near ones.
FAR_SHIFT = {"arm": (13, 9), "thigh": (-24, 0), "shin": (-24, 0), "shoe": (-24, 0)}
# Where the crown of the head is, for hats (canvas px).
CROWN = (287, 37)

# Bones: name, parent, head, tail (canvas px).
BONES = [
    ("spine", -1, (300, 576), (290, 296)),
    ("head", 0, (290, 296), (270, 40)),
    ("hair", 1, (201, 140), (190, 340)),
    ("hair2", 2, (190, 340), (180, 548)),
    ("near_upper", 0, (257, 331), (268, 567)),
    ("near_lower", 4, (268, 567), (272, 745)),
    ("near_hand", 5, (272, 745), (279, 867)),
    ("far_upper", 0, (270, 340), (281, 576)),
    ("far_lower", 7, (281, 576), (285, 754)),
    ("far_hand", 8, (285, 754), (292, 876)),
    ("near_thigh", -1, (318, 636), (352, 1014)),
    ("near_shin", 10, (352, 1014), (352, 1314)),
    ("near_foot", 11, (352, 1314), (480, 1420)),
    ("far_thigh", -1, (294, 636), (328, 1014)),
    ("far_shin", 13, (328, 1014), (328, 1314)),
    ("far_foot", 14, (328, 1314), (456, 1420)),
]
NAME = {b[0]: i for i, b in enumerate(BONES)}
BONE_AT = {b[0]: (np.array(b[2], float), np.array(b[3], float)) for b in BONES}

# Layers back to front: name, part, bones (for the chain rules), far shift.
LAYERS = [
    ("hair_back", "hair_back", None, None),
    ("far_arm", "arm", ["far_upper", "far_lower", "far_hand"], FAR_SHIFT["arm"]),
    ("far_shin", "shin", ["far_shin"], FAR_SHIFT["shin"]),
    ("far_shoe", "shoe", ["far_foot"], FAR_SHIFT["shoe"]),
    ("far_thigh", "thigh", ["far_thigh"], FAR_SHIFT["thigh"]),
    ("near_shin", "shin", ["near_shin"], None),
    ("near_shoe", "shoe", ["near_foot"], None),
    ("near_thigh", "thigh", ["near_thigh"], None),
    ("skirt", "skirt", None, None),
    ("head", "head", None, None),
    ("head_front", "head_front", None, None),
    ("body", "torso", None, None),
    ("near_arm", "arm", ["near_upper", "near_lower", "near_hand"], None),
]
FILE = {"hair_back": "side_hair.png", "arm": "side_arm.png", "thigh": "side_thigh.png", "shin": "side_shin.png", "shoe": "side_shoe.png", "head_front": "side_head_front.png",
        "skirt": "side_skirt.png", "head": "side_head.png", "torso": "side_body.png"}
# Blend width (canvas px) around the inner joints of a limb chain.
BLEND = {"arm": (60, 40), "leg": (70, 45)}


def load_kit_piece(name):
    """A piece of the paper-doll kit: keyed off the black, the glow outside
    the outline dropped, holes (the dark shoe) filled, cut round at the
    knee for the thigh."""
    from scipy import ndimage
    rgb = np.array(Image.open(KIT_SRC).convert("RGB")).astype(int)
    lum = rgb.max(axis=2)
    mask = ndimage.binary_fill_holes(lum > 110)
    x0, y0, x1, y1 = KIT_BOX[name]
    box = np.zeros_like(mask)
    box[y0:y1, x0:x1] = True
    mask &= box
    if name == "thigh":
        (kx, ky), r = KIT_KNEE
        yy, xx = np.mgrid[0:mask.shape[0], 0:mask.shape[1]]
        mask &= (yy < ky) | ((xx - kx) ** 2 + (yy - ky) ** 2 <= r * r)
    mask = ndimage.binary_erosion(mask, iterations=3)
    alpha = ndimage.gaussian_filter(mask.astype(np.float32), 1.0) * 255
    a = np.dstack([rgb.astype(np.float32), alpha])
    if name == "shin":
        (rx, ry), r = KIT_SHIN_RIVET
        yy, xx = np.mgrid[0:mask.shape[0], 0:mask.shape[1]]
        ring = (xx - rx) ** 2 + (yy - ry) ** 2 <= r * r
        a[ring, 0:3] = np.array([246, 244, 242], np.float32)
    return a


def load_part(name):
    if name in KIT_BOX:
        a = load_kit_piece(name)
    elif name == "head_front":
        im = Image.open(FRONT_SRC).convert("RGBA").crop(FRONT_BOX)
        a = np.array(im).astype(np.float32)
        # The cut through the hair and neck fades out.
        rows = a.shape[0]
        fade = np.clip((rows - 1 - np.arange(rows)) / FRONT_FADE, 0, 1)
        a[:, :, 3] *= fade[:, None]
    else:
        im = Image.open(f"{IDEA}/part_{name}.png").convert("RGBA")
        a = np.array(im).astype(np.float32)
        # Trim the glow: only nearly opaque pixels stay, with a short ramp.
        a[:, :, 3] = np.clip((a[:, :, 3] - 120) / (255 - 120), 0, 1) * 255
    top = 0  # drawing y of the first row of a
    m = a[:, :, 3] > 8
    ys, xs = np.where(m)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    crop = Image.fromarray(a[y0:y1, x0:x1].astype(np.uint8), "RGBA")
    (ax, ay), (cx, cy), sx, sy = PARTS[name]
    size = (max(1, round(crop.width * sx)), max(1, round(crop.height * sy)))
    scaled = crop.resize(size, Image.LANCZOS)
    # Canvas position of the top-left corner of the crop.
    ox = cx + (x0 - ax) * sx
    oy = cy + (y0 + top - ay) * sy
    return scaled, (ox, oy)


def chain_weights(p, bones, blends):
    """Weights along a limb chain: one bone per stretch, blended near the
    inner joints. p is a canvas point; bones the names of the chain."""
    joints = [BONE_AT[bones[0]][0]] + [BONE_AT[b][1] for b in bones]
    lengths = [np.linalg.norm(joints[i + 1] - joints[i]) for i in range(len(bones))]
    # Arc length of the closest point on the chain.
    best = None
    for i in range(len(bones)):
        a, b = joints[i], joints[i + 1]
        ab = b - a
        t = float(np.clip(((p - a) @ ab) / (ab @ ab), 0, 1))
        d = float(np.linalg.norm(p - (a + t * ab)))
        s = sum(lengths[:i]) + t * lengths[i]
        if best is None or d < best[0]:
            best = (d, s)
    s = best[1]
    w = {}
    cum = np.cumsum(lengths)
    if bones[-1].endswith("_foot"):
        # The shoe belongs to the foot whole, so the heel keeps its shape
        # when the foot turns on its own; the sock above the ankle goes
        # from the shin at the top to the foot at the bottom, so there is
        # no seam where the two turn differently.
        ankle_y = joints[2][1]
        u = min(1.0, max(0.0, (p[1] - (ankle_y - 64)) / 52))
        if u > 0:
            if u < 1:
                w[NAME[bones[1]]] = 1 - u
            w[NAME[bones[2]]] = u
            return w
        blends = blends[:1]
    for k, b in enumerate(blends):
        S = cum[k]
        if s < S - b:
            w[NAME[bones[k]]] = 1.0
            return w
        if s <= S + b:
            u = (s - (S - b)) / (2 * b)
            w[NAME[bones[k]]] = 1 - u
            w[NAME[bones[k + 1]]] = u
            return w
    w[NAME[bones[-1]]] = 1.0
    return w


def weights_for(layer, part, bones, x, y):
    w = {}
    if bones is not None and len(bones) == 1:
        # A rigid piece on one bone.
        return {NAME[bones[0]]: 1.0}
    if bones is not None:
        return chain_weights(np.array([x, y], float), bones, BLEND[part])
    if layer == "body":
        w[NAME["spine"]] = 1.0
    elif layer in ("head", "head_front"):
        w[NAME["head"]] = 1.0
    elif layer == "skirt":
        # The waistband stays on the belt; below it the skirt hangs from the
        # waist and is carried by the thighs, its front half by the near one
        # and its back half by the far one. (The app swaps the two so the
        # front always goes with whichever thigh is forward, and swings the
        # panels from the waist rather than turning them about the hip.)
        t = min(1.0, max(0.0, (y - 556) / 110))
        side = min(1.0, max(0.0, (x - 240) / 100))
        w[NAME["near_thigh"]] = t * side
        w[NAME["far_thigh"]] = t * (1 - side)
        w[NAME["spine"]] = 1 - t
    elif layer == "hair_back":
        # The crown sits on the head; the length hangs from two bones so
        # the ends trail a little behind the sway.
        k = min(1.0, max(0.0, (y - 150) / 130))
        k2 = min(1.0, max(0.0, (y - 300) / 140))
        w[NAME["head"]] = 1 - k
        w[NAME["hair"]] = k * (1 - k2)
        w[NAME["hair2"]] = k * k2
    return w


# Heel and toe of the sole relative to the ankle, for standing the figure
# on the floor and for the pedals.
SOLE = [[-45, 130], [130, 128]]
rig = {"size": [W, H], "floor": FLOOR, "crown": list(CROWN), "sole": SOLE, "bones": [], "layers": []}
for name, parent, head, tail in BONES:
    rig["bones"].append({"name": name, "parent": parent, "head": list(head), "tail": list(tail)})

STEP = 14
images = {}
composite = Image.new("RGBA", (W, H), (0, 0, 0, 0))
for order, (layer, part, bones, shift) in enumerate(LAYERS):
    if part not in images:
        images[part] = load_part(part)
        images[part][0].save(f"{OUT}/{FILE[part]}", optimize=True)
    img, (ox, oy) = images[part]
    if shift:
        ox, oy = ox + shift[0], oy + shift[1]
    ox, oy = int(round(ox)), int(round(oy))
    alpha = np.array(img)[:, :, 3] > 10
    h, w = alpha.shape
    cols = list(range(0, w, STEP)) + [w]
    rows = list(range(0, h, STEP)) + [h]
    index = {}
    verts = []
    tris = []

    def vid(x, y):
        k = (x, y)
        if k not in index:
            index[k] = len(verts)
            verts.append((x, y))
        return index[k]

    for j in range(len(rows) - 1):
        for i in range(len(cols) - 1):
            cx0, cx1, cy0, cy1 = cols[i], cols[i + 1], rows[j], rows[j + 1]
            if not alpha[cy0:cy1, cx0:cx1].any():
                continue
            a, b, c, d = vid(cx0, cy0), vid(cx1, cy0), vid(cx0, cy1), vid(cx1, cy1)
            tris += [a, b, c, b, d, c]
    weights = []
    for (vx, vy) in verts:
        w = weights_for(layer, part, bones, vx + ox, vy + oy)
        total = float(sum(w.values()))
        keep = [(int(k), float(v) / total) for k, v in w.items() if float(v) / total > 0.02]
        total = sum(v for _, v in keep)
        weights.append([[k, round(v / total, 4)] for k, v in keep])
    rig["layers"].append({
        "name": layer, "image": FILE[part], "order": order, "offset": [ox, oy],
        "verts": [[int(x + ox), int(y + oy)] for x, y in verts], "tris": tris, "weights": weights,
    })
    composite.paste(img, (ox, oy), img)
    print(layer, img.size, "at", (ox, oy), "verts", len(verts), "tris", len(tris) // 3)

json.dump(rig, open(f"{OUT}/side.json", "w"), separators=(",", ":"))
print("json", os.path.getsize(f"{OUT}/side.json"))

# Preview: the assembled rest pose, once plain and once with the bones.
prev = Image.new("RGBA", (W * 2, H), (255, 255, 255, 255))
prev.paste(composite, (0, 0), composite)
prev.paste(composite, (W, 0), composite)
d = ImageDraw.Draw(prev)
for name, parent, head, tail in BONES:
    d.line([(W + head[0], head[1]), (W + tail[0], tail[1])], fill=(255, 0, 0, 255), width=5)
    d.ellipse([W + head[0] - 7, head[1] - 7, W + head[0] + 7, head[1] + 7], fill=(0, 0, 255, 255))
d.line([(0, FLOOR), (2 * W, FLOOR)], fill=(0, 160, 0, 255), width=2)
prev = prev.resize((prev.width * 2 // 3, prev.height * 2 // 3), Image.LANCZOS)
os.makedirs(f"{ROOT}/build", exist_ok=True)
prev.save(f"{ROOT}/build/rig_preview.png")
print("preview", prev.size)
