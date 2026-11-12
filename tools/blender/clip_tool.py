"""Builds one animation clip out of pieces of Meshy clips and saves it skeleton-only.

  blender --background --python tools/blender/clip_tool.py -- <in.glb> <out.glb> <NewName> [options] <piece> ...
    piece:        Clip[:from[:to]]   (seconds; Clip may be part of the action name)
    --turn=DEG    turns the whole body around the vertical axis (e.g. an archery clip that
                  aims to the left: --turn=-90 makes it aim forward)
    --hold=SEC    repeats the last pose for SEC seconds at the end (for looping poses)
    --floor       lowers the body so the feet/legs touch the ground as when standing (Meshy
                  floor-sitting clips float in the air)

Pieces play one after the other. The output has only the armature and the new clip, so in
Godot it is imported as an animation library (see docs/MESHY.md). The 24 Meshy bones keep
their names and rest pose, so the clip plays on the game character as any other.
"""
import math
import sys

import bpy
import mathutils

args = sys.argv[sys.argv.index("--") + 1:]
src, dst, new_name = args[0], args[1], args[2]
turn = 0.0
hold = 0.0
floor = False
pieces = []
for a in args[3:]:
    if a.startswith("--turn="):
        turn = float(a[7:])
    elif a.startswith("--hold="):
        hold = float(a[7:])
    elif a == "--floor":
        floor = True
    else:
        pieces.append(a)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=src, bone_heuristic="BLENDER")
arm = next(o for o in bpy.data.objects if o.type == "ARMATURE")
for o in [o for o in bpy.data.objects if o.type != "ARMATURE"]:
    bpy.data.objects.remove(o, do_unlink=True)
sc = bpy.context.scene
fps = sc.render.fps / sc.render.fps_base
if arm.animation_data is None:
    arm.animation_data_create()


def find_action(part):
    for act in bpy.data.actions:
        if part in act.name:
            return act
    raise SystemExit("no action like " + part + " in " + str([a.name for a in bpy.data.actions]))


# Sample every piece frame by frame (pose of every bone), then write one new action.
frames = []  # list of {bone: (loc, quat, scale)}
LOW_BONES = ["LeftFoot", "RightFoot", "LeftToeBase", "RightToeBase", "LeftLeg", "RightLeg"]
stand_low = min(arm.data.bones[b].head_local.z for b in LOW_BONES if b in arm.data.bones)
lowest = 1e9
for p in pieces:
    bits = p.split(":")
    act = find_action(bits[0])
    f0 = act.frame_range[0] + (float(bits[1]) * fps if len(bits) > 1 and bits[1] else 0.0)
    f1 = act.frame_range[0] + float(bits[2]) * fps if len(bits) > 2 and bits[2] else act.frame_range[1]
    arm.animation_data.action = act
    f = f0
    while f <= f1 + 1e-4:
        sc.frame_set(int(math.floor(f)), subframe=f - math.floor(f))
        frames.append({pb.name: (pb.location.copy(), pb.rotation_quaternion.copy(), pb.scale.copy()) for pb in arm.pose.bones})
        lowest = min(lowest, min(arm.pose.bones[b].head.z for b in LOW_BONES if b in arm.pose.bones))
        f += 1.0
    print("piece %s: %s frames %.1f-%.1f" % (p, act.name, f0, f1))
if hold > 0:
    frames += [frames[-1]] * int(round(hold * fps))

drop = (lowest - stand_low) if floor else 0.0
if floor:
    print("floor: lowest leg point %.2f, standing %.2f -> lowering %.2f" % (lowest, stand_low, drop))
R = mathutils.Matrix.Translation((0, 0, -drop)) @ mathutils.Matrix.Rotation(math.radians(turn), 4, "Z")
root = next(b for b in arm.pose.bones if b.parent is None)
rest = root.bone.matrix_local
new = bpy.data.actions.new(new_name)
arm.animation_data.action = new
for i, pose in enumerate(frames):
    for pb in arm.pose.bones:
        loc, quat, scale = pose[pb.name]
        pb.rotation_mode = "QUATERNION"
        if pb == root and (turn != 0.0 or drop != 0.0):
            basis = mathutils.Matrix.LocRotScale(loc, quat, scale)
            m = rest.inverted() @ R @ rest @ basis
            loc, quat, scale = m.decompose()
        pb.location, pb.rotation_quaternion, pb.scale = loc, quat, scale
        pb.keyframe_insert("location", frame=i + 1)
        pb.keyframe_insert("rotation_quaternion", frame=i + 1)
        pb.keyframe_insert("scale", frame=i + 1)
for act in [a for a in bpy.data.actions if a != new]:
    bpy.data.actions.remove(act)
sc.frame_start, sc.frame_end = 1, len(frames)
arm.select_set(True)
bpy.context.view_layer.objects.active = arm
bpy.ops.export_scene.gltf(filepath=dst, export_format="GLB", use_selection=True, export_animations=True,
                          export_animation_mode="ACTIONS", export_yup=True, export_def_bones=False,
                          export_skins=True)
print("CLIP_OK %s %s %.2f s (%d frames at %g fps)" % (dst, new_name, (len(frames) - 1) / fps, len(frames), fps))
