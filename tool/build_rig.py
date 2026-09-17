"""Builds the side-view rigs from parts drawn one per image or as paper-doll
kits (idea/part_*.png): each part is trimmed, scaled onto a common figure
canvas, covered by a small triangle mesh and skinned to the bones. The arm
and leg are drawn once and used for both the near and the far side. Joint
positions were read off a 100 px grid over each drawing.

One rig per outfit: the uniform (side.json), the swimsuit (side_swim.json)
and the gym clothes (side_gym.json), sharing the head, hair and thigh.
Writes assets/companion/rig/*.json and the layer images, and a preview of
each rest pose with the bones to build/rig_preview_<outfit>.png."""
import json
import os

import numpy as np
from PIL import Image, ImageDraw
from scipy import ndimage

SP = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(SP)
IDEA = f"{ROOT}/idea"
OUT = f"{ROOT}/assets/companion/rig"

W, H = 520, 1460
FLOOR = 1448
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
    ("near_foot", 11, (352, 1314), (470, 1418)),
    ("far_thigh", -1, (294, 636), (328, 1014)),
    ("far_shin", 13, (328, 1014), (328, 1314)),
    ("far_foot", 14, (328, 1314), (446, 1418)),
]
NAME = {b[0]: i for i, b in enumerate(BONES)}
BONE_AT = {b[0]: (np.array(b[2], float), np.array(b[3], float)) for b in BONES}

# Where the far copies sit relative to the near ones.
FAR_SHIFT = {"arm": (13, 9), "leg": (-24, 0)}

# Blend width (canvas px) around the inner joints of a limb chain.
BLEND = {"arm": (60, 40), "leg": (70,)}
# The knee: a sharp change on the back of the leg, where the bend closes
# into a crease, and a wide one across the front, where the kneecap
# stretches over the bend. The elbow bends the other way.
KNEE_HALF = 44
KNEE_BLEND_BACK = 16
KNEE_BLEND_FRONT = 96
ELBOW_HALF = 42
ELBOW_BLEND_FRONT = 18
ELBOW_BLEND_BACK = 80
# The thigh fades out over the shin in a band centred this far above the
# knee (negative: below it), of this half-height (kit px): just under the
# joint, where the shin is at its full width and the two drawings match.
KNEE_SEAM_UP = -28
KNEE_SEAM = 28
# The knee patch: a disc of the leg image around the knee joint, drawn over
# the leg and turned by the average of the thigh and the shin.
KNEE_R = 34
KNEE_FEATHER = 10
ELBOW_R = 30
# The calf is widened on its own, row by row, so the shin can match the
# thigh at the knee and still have a calf: the bulge peaks at this kit y,
# with this spread, by this much.
CALF_Y = 380
CALF_SPREAD = 120
CALF_BULGE = 0.14

# Heel and toe of the sole relative to the ankle, per shoe, for standing the
# figure on the floor and for the pedals.
SOLE = {"loafer": [[-42, 119], [120, 117]], "sneaker": [[-78, 119], [156, 117]]}

# Parts. kind: "idea" (transparent drawing with a glow in the alpha), "kit"
# (a piece of a kit drawing on black), "front" (the front-view sprite).
# anchor -> canvas gives the placement; sx, sy the scale. Boxes are in the
# drawing's own pixels. Rivets are the hinge marks the kits carry, filled
# from the colour around them or with a given colour.
PARTS = {
    "torso": dict(kind="idea", src="part_torso.png", anchor=(541, 1249), canvas=(300, 576), sx=0.315, sy=0.315),
    "skirt": dict(kind="idea", src="part_skirt.png", anchor=(512, 240), canvas=(290, 536), sx=0.32, sy=0.344),
    "head": dict(kind="idea", src="part_head.png", anchor=(540, 1250), canvas=(290, 292), sx=0.24, sy=0.24),
    "hair_back": dict(kind="idea", src="part_hair_back.png", anchor=(430, 350), canvas=(201, 140), sx=0.28, sy=0.37),
    "arm": dict(kind="idea", src="part_arm.png", anchor=(490, 150), canvas=(257, 331), sx=0.40, sy=0.40),
    "head_front": dict(kind="front", src="stand_front.png", box=(22, 0, 112, 88), fade=12, anchor=(67, 80), canvas=(290, 292), sx=3.1, sy=3.1),
    "head_quarter": dict(kind="kit", src="part_head_quarter.png", box=(23, 126, 990, 1324), anchor=(520, 1215), canvas=(290, 292), sx=0.245, sy=0.245, fade=60, match="head"),
    # The leg kit: the thigh piece was drawn down to the ankle, so it is cut
    # at the knee; the shin's round top is cut flat under the thigh.
    "thigh": dict(kind="kit", src="part_leg_kit.png", box=(20, 10, 360, 900), anchor=(152, 72), canvas=(318, 636), sx=0.40, sy=0.534, knee=(215, 780)),
    "shin": dict(kind="kit", src="part_leg_kit.png", box=(405, 160, 675, 1310), anchor=(560, 1240), canvas=(352, 1314), sx=0.34, sy=0.314,
                 rivets=[((560, 1240), 52, (246, 244, 242)), ((560, 190), 64, None)], calf=True),
    "shoe": dict(kind="kit", src="part_leg_kit.png", box=(700, 1062, 1125, 1330), anchor=(820, 1030), canvas=(352, 1314), sx=0.48, sy=0.48),
    # The swimsuit kit: torso, bare arm, bare lower leg with the foot.
    # The body's shoulder hinge (a ring inside the armhole) is filled from
    # the skin around it, so it does not show when the arm swings away.
    "swim_body": dict(kind="kit", src="part_swim_kit.png", box=(120, 150, 513, 965), anchor=(300, 150), canvas=(290, 296), sx=0.53, sy=0.53,
                      rivets=[((240, 268), 86, None)]),
    "swim_arm": dict(kind="kit", src="part_swim_kit.png", box=(638, 110, 825, 1043), anchor=(735, 100), canvas=(257, 331), sx=0.568, sy=0.568,
                     rivets=[((735, 100), 40, None)]),
    # The lower leg is taken from under its round top, where it is already
    # at full width, and set just above the knee so the thigh covers the cut.
    "swim_leg": dict(kind="kit", src="part_swim_kit.png", box=(1038, 150, 1378, 1026), anchor=(1155, 150), canvas=(352, 1000), sx=0.46, sy=0.5),
    # The gym kit: shirt, arm with the short sleeve, shorts, sneaker.
    "gym_body": dict(kind="kit", src="part_gym_kit.png", box=(50, 150, 430, 800), anchor=(200, 150), canvas=(267, 296), sx=0.49, sy=0.49,
                     rivets=[((145, 262), 64, None)]),
    "gym_arm": dict(kind="kit", src="part_gym_kit.png", box=(467, 100, 649, 974), anchor=(560, 80), canvas=(257, 331), sx=0.60, sy=0.60,
                    rivets=[((560, 80), 30, None)]),
    "gym_shorts": dict(kind="kit", src="part_gym_kit.png", box=(698, 440, 1032, 881), anchor=(885, 440), canvas=(290, 560), sx=0.62, sy=0.62),
    "gym_shoe": dict(kind="kit", src="part_gym_kit.png", box=(1095, 730, 1499, 903), anchor=(1230, 690), canvas=(352, 1314), sx=0.58, sy=0.58),
}

# Outfits: which part fills each role. Roles without a part are left out.
OUTFITS = {
    "uniform": dict(file="side.json", torso="torso", arm="arm", skirt="skirt", shin="shin", shoe="shoe", sole="loafer"),
    "swim": dict(file="side_swim.json", torso="swim_body", arm="swim_arm", skirt=None, shin="swim_leg", shoe=None, sole="loafer"),
    "gym": dict(file="side_gym.json", torso="gym_body", arm="gym_arm", skirt="gym_shorts", shin="shin", shoe="gym_shoe", sole="sneaker"),
}

_images = {}


def load_image(name):
    if name not in _images:
        path = f"{IDEA}/{name}" if os.path.exists(f"{IDEA}/{name}") else f"{ROOT}/assets/companion/{name}"
        _images[name] = Image.open(path)
    return _images[name]


def fill_rivets(a, mask, lum, rivets):
    """The hinge marks the kit drew: filled from the colours around them (a
    blur of the surrounding skin only) or with a flat colour, so the
    shading runs on through where they were."""
    yy, xx = np.mgrid[0:mask.shape[0], 0:mask.shape[1]]
    for (rx, ry), r, colour in rivets:
        disc = (xx - rx) ** 2 + (yy - ry) ** 2 <= r * r
        if colour is not None:
            a[disc, 0:3] = np.array(colour, np.float32)
            continue
        keep = (mask & ~disc & (lum > 170)).astype(np.float32)
        # A near blur where there is skin close by, a wide one where there
        # is not (next to dark cloth or the edge), so no spot is left dark.
        near = ndimage.gaussian_filter(keep, 18)
        wide = ndimage.gaussian_filter(keep, 60)
        for c in range(3):
            fill_near = ndimage.gaussian_filter(a[:, :, c] * keep, 18) / np.maximum(near, 1e-6)
            fill_wide = ndimage.gaussian_filter(a[:, :, c] * keep, 60) / np.maximum(wide, 1e-6)
            t = np.clip(near / 0.25, 0, 1)
            a[:, :, c] = np.where(disc, fill_near * t + fill_wide * (1 - t), a[:, :, c])


def hair_mean(rgba):
    """The mean colour of the top third of a drawing, where the hair is."""
    top = rgba[: rgba.shape[0] // 3]
    m = top[:, :, 3] > 200
    return top[m][:, :3].mean(axis=0)


def match_colour(a, ref_name):
    """Pulls a drawing's colours toward another part's (the hair of the
    side head), by a per-channel gain measured on the top third of each."""
    ref = np.array(load_image(PARTS[ref_name]["src"]).convert("RGBA")).astype(np.float32)
    ref[:, :, 3] = np.clip((ref[:, :, 3] - 120) / (255 - 120), 0, 1) * 255
    gain = np.clip(hair_mean(ref) / np.maximum(hair_mean(a), 1), 0.75, 1.25)
    a[:, :, :3] = np.clip(a[:, :, :3] * gain, 0, 255)


def load_part(name):
    spec = PARTS[name]
    kind = spec["kind"]
    if kind == "idea":
        im = load_image(spec["src"]).convert("RGBA")
        a = np.array(im).astype(np.float32)
        # Trim the glow: only nearly opaque pixels stay, with a short ramp.
        a[:, :, 3] = np.clip((a[:, :, 3] - 120) / (255 - 120), 0, 1) * 255
    elif kind == "front":
        im = load_image(spec["src"]).convert("RGBA").crop(spec["box"])
        a = np.array(im).astype(np.float32)
        rows = a.shape[0]
        a[:, :, 3] *= np.clip((rows - 1 - np.arange(rows)) / spec["fade"], 0, 1)[:, None]
    else:
        rgb = np.array(load_image(spec["src"]).convert("RGB")).astype(int)
        lum = rgb.max(axis=2)
        # Everything brighter than the black background, holes filled.
        mask = ndimage.binary_fill_holes(lum > 110)
        x0, y0, x1, y1 = spec["box"]
        box = np.zeros_like(mask)
        box[y0:y1, x0:x1] = True
        mask &= box
        rows = np.arange(mask.shape[0])
        if "knee" in spec:
            # The thigh ends just above the knee, fading out level over the
            # opaque shin, so the two make one leg with no step in the
            # outline at the knee.
            ky = spec["knee"][1]
            mask &= rows[:, None] < ky - KNEE_SEAM_UP + KNEE_SEAM
        mask = ndimage.binary_erosion(mask, iterations=3)
        alpha = ndimage.gaussian_filter(mask.astype(np.float32), 1.0) * 255
        if "knee" in spec:
            ky = spec["knee"][1]
            alpha = alpha * np.clip((ky - KNEE_SEAM_UP + KNEE_SEAM - rows) / (2 * KNEE_SEAM), 0, 1)[:, None]
        if "fade" in spec:
            # The cut through the neck fades out.
            alpha = alpha * np.clip((y1 - 1 - rows) / spec["fade"], 0, 1)[:, None]
        a = np.dstack([rgb.astype(np.float32), alpha])
        if spec.get("rivets"):
            fill_rivets(a, mask, lum, spec["rivets"])
        if spec.get("match"):
            match_colour(a, spec["match"])
    m = a[:, :, 3] > 8
    ys, xs = np.where(m)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    crop = Image.fromarray(a[y0:y1, x0:x1].astype(np.uint8), "RGBA")
    (ax, ay), (cx, cy), sx, sy = spec["anchor"], spec["canvas"], spec["sx"], spec["sy"]
    size = (max(1, round(crop.width * sx)), max(1, round(crop.height * sy)))
    scaled = crop.resize(size, Image.LANCZOS)
    # Canvas position of the top-left corner of the crop.
    ox = cx + (x0 - ax) * sx
    oy = cy + (y0 - ay) * sy
    if spec.get("calf"):
        scaled, ox = calf_bulge(scaled, ox, y0, sy)
    return scaled, (ox, oy)


def calf_bulge(img, ox, y0, sy):
    """Widens each row of the shin about its own centre by a bump that
    peaks at the calf."""
    a = np.array(img).astype(np.float32)
    h, w = a.shape[:2]
    pad = int(w * CALF_BULGE) + 2
    out = np.zeros((h, w + 2 * pad, 4), np.float32)
    xs = np.arange(w + 2 * pad, dtype=np.float32) - pad
    for i in range(h):
        y = y0 + i / sy
        f = 1 + CALF_BULGE * np.exp(-((y - CALF_Y) / CALF_SPREAD) ** 2)
        row = a[i]
        alpha = row[:, 3]
        if alpha.sum() < 1:
            continue
        c = float((alpha * np.arange(w)).sum() / alpha.sum())
        src = c + (xs - c) / f
        for ch in range(4):
            out[i, :, ch] = np.interp(src, np.arange(w), row[:, ch], left=0, right=0)
    return Image.fromarray(out.astype(np.uint8), "RGBA"), ox - pad


def compose(parts):
    """Several placed parts flattened into one image, in the order given."""
    x0 = min(int(round(o[0])) for _, o in parts)
    y0 = min(int(round(o[1])) for _, o in parts)
    x1 = max(int(round(o[0])) + im.width for im, o in parts)
    y1 = max(int(round(o[1])) + im.height for im, o in parts)
    canvas = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
    for im, (ox, oy) in parts:
        canvas.alpha_composite(im, (int(round(ox)) - x0, int(round(oy)) - y0))
    return canvas, (x0, y0)


def compose_patch(part, joint, radius):
    """A disc of a part's image around a joint, feathered."""
    img, (ox, oy) = part
    kx, ky = joint
    a = np.array(img).astype(np.float32)
    yy, xx = np.mgrid[0:a.shape[0], 0:a.shape[1]]
    d = np.sqrt((xx + ox - kx) ** 2 + (yy + oy - ky) ** 2)
    a[:, :, 3] *= np.clip((radius - d) / KNEE_FEATHER, 0, 1)
    m = a[:, :, 3] > 4
    ys, xs = np.where(m)
    x0, y0, x1, y1 = xs.min(), ys.min(), xs.max() + 1, ys.max() + 1
    return Image.fromarray(a[y0:y1, x0:x1].astype(np.uint8), "RGBA"), (ox + x0, oy + y0)


def chain_weights(p, bones, blends):
    """Weights along a limb chain: one bone per stretch, blended near the
    inner joints. p is a canvas point; bones the names of the chain."""
    joints = [BONE_AT[bones[0]][0]] + [BONE_AT[b][1] for b in bones]
    lengths = [np.linalg.norm(joints[i + 1] - joints[i]) for i in range(len(bones))]
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
    if bones[-1].endswith("_hand"):
        ex = joints[1][0]
        t = min(1.0, max(0.0, (p[0] - (ex - ELBOW_HALF)) / (2 * ELBOW_HALF)))
        blends = (ELBOW_BLEND_BACK + (ELBOW_BLEND_FRONT - ELBOW_BLEND_BACK) * t, blends[1])
    if bones[-1].endswith("_shin"):
        kx = joints[1][0]
        t = min(1.0, max(0.0, (p[0] - (kx - KNEE_HALF)) / (2 * KNEE_HALF)))
        blends = (KNEE_BLEND_BACK + (KNEE_BLEND_FRONT - KNEE_BLEND_BACK) * t,)
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


def weights_for(role, bones, x, y):
    w = {}
    if role in ("knee", "elbow"):
        return {NAME[bones[0]]: 0.5, NAME[bones[1]]: 0.5}
    if bones is not None and len(bones) == 1:
        return {NAME[bones[0]]: 1.0}
    if bones is not None:
        return chain_weights(np.array([x, y], float), bones, BLEND["arm" if bones[-1].endswith("_hand") else "leg"])
    if role == "body":
        w[NAME["spine"]] = 1.0
    elif role in ("head", "head_front", "head_quarter"):
        w[NAME["head"]] = 1.0
    elif role == "skirt":
        # The waistband stays on the belt; below it the skirt (or shorts)
        # hangs from the waist and is carried by the thighs, its front half
        # by the near one and its back half by the far one. (The app swaps
        # the two so the front always goes with whichever thigh is forward,
        # and swings the panels from the waist.)
        t = min(1.0, max(0.0, (y - 556) / 110))
        side = min(1.0, max(0.0, (x - 240) / 100))
        w[NAME["near_thigh"]] = t * side
        w[NAME["far_thigh"]] = t * (1 - side)
        w[NAME["spine"]] = 1 - t
    elif role == "hair_back":
        # The crown sits on the head; the length hangs from two bones so
        # the ends trail a little behind the sway.
        k = min(1.0, max(0.0, (y - 150) / 130))
        k2 = min(1.0, max(0.0, (y - 300) / 140))
        w[NAME["head"]] = 1 - k
        w[NAME["hair"]] = k * (1 - k2)
        w[NAME["hair2"]] = k * k2
    return w


STEP = 14


def mesh(img, ox, oy, role, bones):
    """A grid mesh over a placed image, with weights per vertex."""
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
        w = weights_for(role, bones, vx + ox, vy + oy)
        total = float(sum(w.values()))
        keep = [(int(k), float(v) / total) for k, v in w.items() if float(v) / total > 0.02]
        total = sum(v for _, v in keep)
        weights.append([[k, round(v / total, 4)] for k, v in keep])
    return [[int(x + ox), int(y + oy)] for x, y in verts], tris, weights


# Parts every outfit shares keep one file each.
SHARED = {"hair_back": "side_hair.png", "head": "side_head.png", "head_front": "side_head_front.png",
          "head_quarter": "side_head_quarter.png"}


def build(outfit, spec):
    parts = {}

    def part(name):
        if name not in parts:
            parts[name] = load_part(name)
        return parts[name]

    torso, arm, skirt, shin, shoe = spec["torso"], spec["arm"], spec["skirt"], spec["shin"], spec["shoe"]
    prefix = "side" if outfit == "uniform" else f"side_{outfit}"
    leg = compose([part(shin), part("thigh")])
    knee = compose_patch(leg, BONE_AT["near_thigh"][1], KNEE_R)
    elbow = compose_patch(part(arm), BONE_AT["near_upper"][1], ELBOW_R)

    def file_for(role, name):
        # The leg (thigh with shin) follows the shin's file; outfits that
        # share the uniform's shin or arm share those files.
        if role in ("leg", "knee"):
            base = "side" if shin == "shin" else prefix
            return f"{base}_{role}.png"
        if role == "elbow":
            base = "side" if arm == "arm" else prefix
            return f"{base}_elbow.png"
        if name in SHARED:
            return SHARED[name]
        if outfit == "uniform":
            return {"torso": "side_body.png", "arm": "side_arm.png", "skirt": "side_skirt.png", "shoe": "side_shoe.png"}[name]
        return f"{prefix}_{name.split('_', 1)[-1]}.png"

    sources = {
        "hair_back": ("hair_back", part("hair_back")),
        "arm": (arm, part(arm)),
        "elbow": ("elbow", elbow),
        "leg": ("leg", leg),
        "knee": ("knee", knee),
        "head": ("head", part("head")),
        "head_quarter": ("head_quarter", part("head_quarter")),
        "head_front": ("head_front", part("head_front")),
        "body": (torso, part(torso)),
    }
    if shoe:
        sources["shoe"] = (shoe, part(shoe))
    if skirt:
        sources["skirt"] = (skirt, part(skirt))

    # Layers back to front.
    layers = [
        ("hair_back", "hair_back", None, None),
        ("far_arm", "arm", ["far_upper", "far_lower", "far_hand"], FAR_SHIFT["arm"]),
        ("far_elbow", "elbow", ["far_upper", "far_lower"], FAR_SHIFT["arm"]),
        ("far_leg", "leg", ["far_thigh", "far_shin"], FAR_SHIFT["leg"]),
        ("far_knee", "knee", ["far_thigh", "far_shin"], FAR_SHIFT["leg"]),
    ]
    if shoe:
        layers.append(("far_shoe", "shoe", ["far_foot"], FAR_SHIFT["leg"]))
    layers += [
        ("near_leg", "leg", ["near_thigh", "near_shin"], None),
        ("near_knee", "knee", ["near_thigh", "near_shin"], None),
    ]
    if shoe:
        layers.append(("near_shoe", "shoe", ["near_foot"], None))
    if skirt:
        layers.append(("skirt", "skirt", None, None))
    layers += [
        ("head", "head", None, None),
        ("head_quarter", "head_quarter", None, None),
        ("head_front", "head_front", None, None),
        ("body", "body", None, None),
        ("near_arm", "arm", ["near_upper", "near_lower", "near_hand"], None),
        ("near_elbow", "elbow", ["near_upper", "near_lower"], None),
    ]

    rig = {"size": [W, H], "floor": FLOOR, "crown": list(CROWN), "sole": SOLE[spec["sole"]], "bones": [], "layers": []}
    for name, parent, head, tail in BONES:
        rig["bones"].append({"name": name, "parent": parent, "head": list(head), "tail": list(tail)})
    composite = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    saved = set()
    for order, (layer, role, bones, shift) in enumerate(layers):
        name, (img, (ox, oy)) = sources[role]
        file = file_for(role, name)
        if file not in saved:
            img.save(f"{OUT}/{file}", optimize=True)
            saved.add(file)
        if shift:
            ox, oy = ox + shift[0], oy + shift[1]
        ox, oy = int(round(ox)), int(round(oy))
        verts, tris, weights = mesh(img, ox, oy, role, bones)
        rig["layers"].append({"name": layer, "image": file, "order": order, "offset": [ox, oy], "verts": verts, "tris": tris, "weights": weights})
        if role not in ("head_front", "head_quarter"):
            composite.paste(img, (ox, oy), img)
        print(f"{outfit:8s} {layer:12s} {img.size} at {(ox, oy)} verts {len(verts)} -> {file}")
    json.dump(rig, open(f"{OUT}/{spec['file']}", "w"), separators=(",", ":"))
    print(outfit, "json", os.path.getsize(f"{OUT}/{spec['file']}"))

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
    prev.save(f"{ROOT}/build/rig_preview_{outfit}.png")


if __name__ == "__main__":
    for outfit, spec in OUTFITS.items():
        build(outfit, spec)
