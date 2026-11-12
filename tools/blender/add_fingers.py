"""Adds finger bones (3 per finger, both hands) to a Meshy humanoid GLB and weights them.

Meshy rigs have 24 bones and no fingers, so hands never close. This script keeps the 24
original bones exactly as they are (all Meshy animations keep working) and adds:
  <Side><Finger><Segment>, e.g. RightIndexProximal, RightThumbMetacarpal (humanoid names).
Each finger bone's local Z points to the palm, so bending a finger = +X rotation.

Run with Blender 4.5 (no window):
  blender --background --python tools/blender/add_fingers.py -- <in.glb> <out.glb> [preview_dir]
With preview_dir, it also renders both hands closed in a fist (for checking the weights).
Then check in Godot that the 24 original bones did not move (see docs/DECISOES.md).
"""
import json
import math
import os
import sys

import bpy
import mathutils
from mathutils.geometry import intersect_point_line

FINGERS = ["Index", "Middle", "Ring", "Little"]
SEGMENTS = {"Thumb": ["Metacarpal", "Proximal", "Distal"]}
DEFAULT_SEGMENTS = ["Proximal", "Intermediate", "Distal"]
# Proportions measured on Lio (hand 19.1 units long from the wrist to the fingertips).
REF_HAND = 19.08
POW = 6.0  # weight falloff: higher = less bleeding between neighbouring fingers


def mean(xs):
    return sum(xs) / len(xs)


def line_fit(pts):
    """Least squares c(a), n(a) through (a, c, n) points."""
    A = [p[0] for p in pts]
    ma = mean(A)
    var = sum((x - ma) ** 2 for x in A) or 1e-6
    res = []
    for k in (1, 2):
        Y = [p[k] for p in pts]
        my = mean(Y)
        slope = sum((A[i] - ma) * (Y[i] - my) for i in range(len(A))) / var
        res.append((my - slope * ma, slope))
    return lambda a: (res[0][0] + res[0][1] * a, res[1][0] + res[1][1] * a)


def hand_frame(arm, side):
    fa = arm.data.bones[side + "ForeArm"].head_local
    h = arm.data.bones[side + "Hand"].head_local.copy()
    a = (h - fa).normalized()
    c = mathutils.Vector((0, 1, 0))
    c = (c - a * c.dot(a)).normalized()
    n = a.cross(c)
    return h, a, c, n


def analyse_hand(arm, mesh, side):
    """Returns joints (hand frame coords) per finger and the finger label of each vertex."""
    me = mesh.data
    h, A, C, N = hand_frame(arm, side)
    gi = mesh.vertex_groups[side + "Hand"].index
    pts = []
    for v in me.vertices:
        w = next((g.weight for g in v.groups if g.group == gi), 0.0)
        if w > 0.01:
            r = v.co - h
            pts.append((v.index, r.dot(A), r.dot(C), r.dot(N), w))
    P = [(p[1], p[2], p[3]) for p in pts if p[4] > 0.3]
    L = max(p[0] for p in P)
    k = L / REF_HAND
    split = 10.3 * k
    F = [p for p in P if p[0] > split]
    palm_sign = 1 if mean([p[2] for p in F]) > 0 else -1
    cent = [-4.2 * k, -1.0 * k, 2.2 * k, 5.0 * k]
    for _ in range(50):
        groups = [[] for _ in cent]
        for p in F:
            groups[min(range(4), key=lambda i: abs(p[1] - cent[i]))].append(p)
        cent = [mean([p[1] for p in g]) if g else cent[i] for i, g in enumerate(groups)]
    joints = {}
    for i, g in enumerate(groups):
        tip_a = max(p[0] for p in g)
        fit = line_fit(g)
        mcp_a = (9.6 if i < 3 else 9.2) * k
        length = tip_a - 0.25 * k - mcp_a
        js = [mcp_a, mcp_a + 0.45 * length, mcp_a + 0.75 * length, tip_a - 0.25 * k]
        joints[FINGERS[i]] = [[a, *fit(a)] for a in js]
    T = [p for p in P if p[1] < cent[0] - 1.8 * k and 0.5 * k < p[0] < 11.5 * k]
    if len(T) < 5:
        # Odd hands (bracelets, mitten-like thumbs): take the outermost points on the thumb side.
        side_pts = sorted([p for p in P if 0.5 * k < p[0] < 11.5 * k], key=lambda p: p[1])
        T = side_pts[:max(8, len(side_pts) // 8)]
    tip = max(T, key=lambda p: p[0] + 0.5 * palm_sign * p[2])
    fit = line_fit([p for p in T if p[0] > 3.0 * k])
    b = [2.0 * k, *fit(2.0 * k)]
    b[1] = b[1] * 0.6 + cent[0] * 0.4  # the thumb root sits inside the hand
    b[2] = b[2] * 0.5
    t = [tip[0] - 0.2 * k, tip[1], tip[2]]
    joints["Thumb"] = [b, [b[i] + (t[i] - b[i]) * 0.42 for i in range(3)],
                       [b[i] + (t[i] - b[i]) * 0.72 for i in range(3)], t]
    labels = {}
    for q in pts:
        a, c = q[1], q[2]
        if c < cent[0] - 1.8 * k and 0.5 * k < a < 11.5 * k:
            labels[q[0]] = "Thumb"
        elif a > split:
            labels[q[0]] = FINGERS[min(range(4), key=lambda i: abs(c - cent[i]))]
    print("%s hand: length %.2f, %d vertices, fingers %s" % (side, L, len(pts), {f: len([1 for v in labels.values() if v == f]) for f in joints}))
    return {"frame": (h, A, C, N), "palm_sign": palm_sign, "joints": joints, "labels": labels, "k": k}


def build_bones(arm, hands):
    bpy.context.view_layer.objects.active = arm
    bpy.ops.object.mode_set(mode="EDIT")
    eb = arm.data.edit_bones
    for side, info in hands.items():
        h, A, C, N = info["frame"]
        palm = N * info["palm_sign"]
        for finger, js in info["joints"].items():
            segs = SEGMENTS.get(finger, DEFAULT_SEGMENTS)
            parent = eb[side + "Hand"]
            for i, seg in enumerate(segs):
                b = eb.get(side + finger + seg) or eb.new(side + finger + seg)
                b.head = h + A * js[i][0] + C * js[i][1] + N * js[i][2]
                b.tail = h + A * js[i + 1][0] + C * js[i + 1][1] + N * js[i + 1][2]
                b.parent = parent
                b.use_connect = i > 0
                b.use_deform = True
                b.align_roll(palm)
                parent = b
    bpy.ops.object.mode_set(mode="OBJECT")


def seg_dist(p, hd, tl):
    _, t = intersect_point_line(p, hd, tl)
    t = max(0.0, min(1.0, t))
    return (p - (hd + (tl - hd) * t)).length


def weight_fingers(arm, mesh, hands):
    """Splits each vertex's original hand weight between the hand and the finger bones."""
    me = mesh.data
    bones = arm.data.bones
    for side, info in hands.items():
        h, A, C, N = info["frame"]
        k = info["k"]
        hand = bones[side + "Hand"]
        fingers = {f: [bones[side + f + s] for s in SEGMENTS.get(f, DEFAULT_SEGMENTS)] for f in info["joints"]}
        knuckle = sum((fingers[f][0].head_local for f in FINGERS), mathutils.Vector()) / 4
        hg = mesh.vertex_groups[side + "Hand"]
        groups = {b.name: (mesh.vertex_groups.get(b.name) or mesh.vertex_groups.new(name=b.name))
                  for fl in fingers.values() for b in fl}
        all_finger_bones = [b for fl in fingers.values() for b in fl]
        for v in me.vertices:
            W = next((g.weight for g in v.groups if g.group == hg.index), 0.0)
            if W <= 0.0:
                continue
            p = v.co
            lab = info["labels"].get(v.index)
            cands = fingers[lab] if lab else all_finger_bones
            ws = {side + "Hand": 1.0 / max(seg_dist(p, hand.head_local, knuckle), 0.05) ** POW}
            for b in cands:
                ws[b.name] = 1.0 / max(seg_dist(p, b.head_local, b.tail_local), 0.05) ** POW
            if not lab:
                # The back of the hand (and wraps/gloves on it) stays with the hand bone.
                a = (p - h).dot(A)
                x = max(0.0, min(1.0, (a - 8.6 * k) / (1.8 * k)))
                gate = x * x * (3 - 2 * x)
                for name in ws:
                    if name != side + "Hand":
                        ws[name] *= gate
            tot = sum(ws.values())
            for name, w in ws.items():
                w = W * w / tot
                if name == side + "Hand":
                    hg.add([v.index], w, "REPLACE")
                elif w > 0.001:
                    groups[name].add([v.index], w, "REPLACE")


def render_fist(arm, hands, out_dir):
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_WORKBENCH"
    sc.display.shading.color_type = "TEXTURE"
    sc.render.resolution_x = sc.render.resolution_y = 500
    cam = bpy.data.objects.new("FistCam", bpy.data.cameras.new("FistCam"))
    sc.collection.objects.link(cam)
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = 0.24 * arm.scale.x * 100
    sc.camera = cam
    curl = {"Index": 70, "Middle": 80, "Ring": 80, "Little": 80}
    for pb in arm.pose.bones:
        pb.rotation_mode = "XYZ"
        for f in FINGERS:
            if f in pb.name:
                pb.rotation_euler = (math.radians(curl[f] if "Proximal" in pb.name else 80 if "Intermediate" in pb.name else 60), 0, 0)
        if "Thumb" in pb.name and "Metacarpal" not in pb.name:
            pb.rotation_euler = (math.radians(40), 0, 0)
    bpy.context.view_layer.update()
    for side, info in hands.items():
        h, A, C, N = info["frame"]
        hw = arm.matrix_world @ h
        for view, look in (("palm", N * info["palm_sign"]), ("side", C)):
            up = -A
            z = -look
            x = up.cross(z)
            cam.matrix_world = mathutils.Matrix.Translation(hw + A * 0.09 * arm.scale.x * 100 - look) @ mathutils.Matrix((x, up, z)).transposed().to_4x4()
            sc.render.filepath = os.path.join(out_dir, "fist_%s_%s.png" % (side, view))
            bpy.ops.render.render(write_still=True)
    for pb in arm.pose.bones:
        pb.rotation_euler = (0, 0, 0)
    bpy.data.objects.remove(cam)


def main():
    args = sys.argv[sys.argv.index("--") + 1:]
    src, dst = args[0], args[1]
    preview = args[2] if len(args) > 2 else ""
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=src, bone_heuristic="BLENDER")
    arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
    mesh = next(o for o in bpy.data.objects if o.type == "MESH")
    if "RightIndexProximal" in arm.data.bones:
        print("already has finger bones")
        return
    hands = {side: analyse_hand(arm, mesh, side) for side in ("Right", "Left")}
    build_bones(arm, hands)
    weight_fingers(arm, mesh, hands)
    if preview:
        os.makedirs(preview, exist_ok=True)
        render_fist(arm, hands, preview)
    for o in bpy.context.view_layer.objects:
        o.select_set(o in (arm, mesh))
    bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", use_selection=True, export_animations=False,
                              export_yup=True, export_skins=True, export_def_bones=False, export_apply=False)
    print("FINGERS_OK", dst, len(arm.data.bones), "bones")


main()
