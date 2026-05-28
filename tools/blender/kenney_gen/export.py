"""Headless GLB export. Material reads per-vertex color (attribute `Col`)
baked by primitives.py — no texture, no mipmap, no block-compression
artifacts. A light emission tint is applied so flat colors stay vibrant
under any lighting."""

import bpy
from pathlib import Path


def _set_input_default(node, names, value):
    for n in names:
        if n in node.inputs:
            node.inputs[n].default_value = value
            return True
    return False


def setup_material(name="kenney_material"):
    if name in bpy.data.materials:
        return bpy.data.materials[name]

    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    links = mat.node_tree.links
    for n in list(nodes):
        nodes.remove(n)

    out = nodes.new("ShaderNodeOutputMaterial")
    bsdf = nodes.new("ShaderNodeBsdfPrincipled")
    attr = nodes.new("ShaderNodeAttribute")
    attr.attribute_name = "Col"
    attr.attribute_type = 'GEOMETRY'

    _set_input_default(bsdf, ("Roughness",), 0.85)
    _set_input_default(bsdf, ("Specular IOR Level", "Specular"), 0.25)
    # Emission is intentionally zero — previous glTF exports translated
    # emission_strength into a constant emissiveFactor that washed out colors.
    _set_input_default(bsdf, ("Emission Strength",), 0.0)

    links.new(attr.outputs["Color"], bsdf.inputs["Base Color"])
    links.new(bsdf.outputs["BSDF"], out.inputs["Surface"])
    return mat


def assign_material_to_all_meshes(mat):
    for obj in bpy.data.objects:
        if obj.type != 'MESH':
            continue
        if obj.data.materials:
            obj.data.materials[0] = mat
        else:
            obj.data.materials.append(mat)


def export_glb(output_path):
    output_path = Path(output_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.export_scene.gltf(
        filepath=str(output_path),
        export_format='GLB',
        use_selection=False,
        export_apply=True,
        export_yup=True,
    )
    return output_path


def clear_scene():
    for obj in list(bpy.data.objects):
        bpy.data.objects.remove(obj, do_unlink=True)
    for mesh in list(bpy.data.meshes):
        bpy.data.meshes.remove(mesh)
    for mat in list(bpy.data.materials):
        bpy.data.materials.remove(mat)
    for img in list(bpy.data.images):
        bpy.data.images.remove(img)
