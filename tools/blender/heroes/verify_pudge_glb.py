#!/usr/bin/env python3
# Story-007 verification — validate the exported GLB at the glTF-data level (what Godot 4.6
# imports). Checks: skin joint count + exact PascalCase bone names, single skeleton root,
# A-pose rest (hands below + outside shoulders, L/R symmetric, feet low, head high),
# Y-up orientation (height on +Y) and ~1.4 m height from the mesh POSITION accessor bounds.
#
# Pure stdlib (struct/json). Run: python3 tools/blender/heroes/verify_pudge_glb.py [glb]

import json
import struct
import sys
import math

GLB = sys.argv[1] if len(sys.argv) > 1 else "tools/blender/heroes/pudge_skeleton_test.glb"

EXPECTED = {
    "Hips", "Spine", "Spine1", "Chest", "Neck", "Head",
    "LeftShoulder", "LeftArm", "LeftForeArm", "LeftHand",
    "RightShoulder", "RightArm", "RightForeArm", "RightHand",
    "LeftUpLeg", "LeftLeg", "LeftFoot",
    "RightUpLeg", "RightLeg", "RightFoot",
}


def load_glb(path):
    with open(path, "rb") as f:
        data = f.read()
    magic, ver, length = struct.unpack_from("<4sII", data, 0)
    assert magic == b"glTF", magic
    off = 12
    gltf_json = None
    while off < length:
        clen, ctype = struct.unpack_from("<II", data, off)
        off += 8
        chunk = data[off:off + clen]
        off += clen
        if ctype == 0x4E4F534A:  # JSON
            gltf_json = json.loads(chunk)
    return gltf_json


def ident():
    return [[1.0 if i == j else 0.0 for j in range(4)] for i in range(4)]


def matmul(a, b):
    return [[sum(a[i][k] * b[k][j] for k in range(4)) for j in range(4)] for i in range(4)]


def trs_to_mat(node):
    if "matrix" in node:  # glTF matrix is column-major
        m = node["matrix"]
        return [[m[j * 4 + i] for j in range(4)] for i in range(4)]
    t = node.get("translation", [0, 0, 0])
    q = node.get("rotation", [0, 0, 0, 1])
    s = node.get("scale", [1, 1, 1])
    x, y, z, w = q
    R = [
        [1 - 2 * (y * y + z * z), 2 * (x * y - z * w), 2 * (x * z + y * w), 0],
        [2 * (x * y + z * w), 1 - 2 * (x * x + z * z), 2 * (y * z - x * w), 0],
        [2 * (x * z - y * w), 2 * (y * z + x * w), 1 - 2 * (x * x + y * y), 0],
        [0, 0, 0, 1],
    ]
    T = ident(); T[0][3], T[1][3], T[2][3] = t
    S = ident(); S[0][0], S[1][1], S[2][2] = s
    return matmul(matmul(T, R), S)


def main():
    g = load_glb(GLB)
    nodes = g["nodes"]
    parent = {}
    for i, n in enumerate(nodes):
        for c in n.get("children", []):
            parent[c] = i

    # world matrices
    world = {}
    def world_of(i):
        if i in world:
            return world[i]
        local = trs_to_mat(nodes[i])
        world[i] = matmul(world_of(parent[i]), local) if i in parent else local
        return world[i]

    skins = g.get("skins", [])
    results = []

    def check(name, ok, detail=""):
        results.append((ok, name, detail))

    check("glTF has exactly one skin", len(skins) == 1, f"skins={len(skins)}")
    joints = skins[0]["joints"] if skins else []
    jnames = {nodes[j].get("name", f"node{j}"): j for j in joints}

    check("20 skin joints", len(joints) == 20, f"joints={len(joints)}")
    missing = EXPECTED - set(jnames)
    extra = set(jnames) - EXPECTED
    check("exact bone-name set (PascalCase preserved)", not missing and not extra,
          f"missing={sorted(missing)} extra={sorted(extra)}")

    # single skeleton root: exactly one joint whose parent is not a joint
    jset = set(joints)
    roots = [nodes[j].get("name") for j in joints if parent.get(j) not in jset]
    check("single skeleton root = Hips", roots == ["Hips"], f"roots={roots}")

    # world positions (Y-up)
    def pos(bone):
        m = world_of(jnames[bone])
        return (m[0][3], m[1][3], m[2][3])

    if not (missing or extra):
        lh, ls = pos("LeftHand"), pos("LeftArm")
        rh, rs = pos("RightHand"), pos("RightArm")
        lf, rf = pos("LeftFoot"), pos("RightFoot")
        head, hips = pos("Head"), pos("Hips")

        check("A-pose: LeftHand below shoulder", lh[1] < ls[1] - 0.15,
              f"hand Y={lh[1]:.3f} < shoulder Y={ls[1]:.3f}")
        check("A-pose: hands outside shoulders (|x| grows)",
              abs(lh[0]) > abs(ls[0]) and abs(rh[0]) > abs(rs[0]),
              f"LH x={lh[0]:.3f} vs LS x={ls[0]:.3f}")
        check("L/R symmetric (hand X mirrored)", abs(lh[0] + rh[0]) < 0.02,
              f"LH x={lh[0]:.3f} RH x={rh[0]:.3f}")
        check("feet near ground plane (Y < 0.12)", lf[1] < 0.12 and rf[1] < 0.12,
              f"LF Y={lf[1]:.3f} RF Y={rf[1]:.3f}")
        check("head above hips (upright)", head[1] > hips[1] + 0.4,
              f"head Y={head[1]:.3f} hips Y={hips[1]:.3f}")

    # mesh orientation + height from POSITION accessor bounds
    meshnode = next((n for n in nodes if "mesh" in n), None)
    prim = g["meshes"][meshnode["mesh"]]["primitives"][0]
    acc = g["accessors"][prim["attributes"]["POSITION"]]
    mn, mx = acc["min"], acc["max"]
    dims = [mx[k] - mn[k] for k in range(3)]
    tallest = dims.index(max(dims))
    check("height axis is +Y (Y-up conversion)", tallest == 1,
          f"dims X={dims[0]:.3f} Y={dims[1]:.3f} Z={dims[2]:.3f}")
    check("total height ~1.4 m (1.33-1.47)", 1.33 <= dims[1] <= 1.47, f"height={dims[1]:.3f}")
    check("feet plane at Y~0", abs(mn[1]) < 0.02, f"min Y={mn[1]:.4f}")
    check("has skinned mesh (JOINTS_0/WEIGHTS_0)",
          "JOINTS_0" in prim["attributes"] and "WEIGHTS_0" in prim["attributes"], "")

    print(f"\n=== Pudge GLB round-trip verification: {GLB} ===\n")
    npass = sum(1 for ok, *_ in results if ok)
    for ok, name, detail in results:
        print(f"  [{'PASS' if ok else 'FAIL'}] {name}" + (f"  ({detail})" if detail else ""))
    print(f"\n  {npass}/{len(results)} checks passed\n")
    sys.exit(0 if npass == len(results) else 1)


if __name__ == "__main__":
    main()
