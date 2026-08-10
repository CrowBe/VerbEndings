import bpy
import hashlib
import json
import math
import sys
from pathlib import Path
from mathutils import Vector


def args() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def bounds(objects: list[bpy.types.Object]) -> tuple[Vector, Vector]:
    points = [obj.matrix_world @ Vector(corner) for obj in objects if obj.type == "MESH" for corner in obj.bound_box]
    return (
        Vector((min(p.x for p in points), min(p.y for p in points), min(p.z for p in points))),
        Vector((max(p.x for p in points), max(p.y for p in points), max(p.z for p in points))),
    )


def look_at(obj: bpy.types.Object, target: Vector) -> None:
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def material(name: str, colour: tuple[float, float, float, float], roughness: float) -> bpy.types.Material:
    result = bpy.data.materials.new(name)
    result.diffuse_color = colour
    result.use_nodes = True
    bsdf = result.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = colour
    bsdf.inputs["Roughness"].default_value = roughness
    return result


def main() -> None:
    values = args()
    if len(values) != 3:
        raise SystemExit(
            "usage: blender --background --python normalise_and_render_glb.py -- "
            "input.glb output.glb output_dir"
        )
    input_path = Path(values[0]).resolve()
    output_glb = Path(values[1]).resolve()
    output_dir = Path(values[2]).resolve()
    output_glb.parent.mkdir(parents=True, exist_ok=True)
    output_dir.mkdir(parents=True, exist_ok=True)

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(input_path))
    asset_objects = [obj for obj in bpy.context.scene.objects if obj.type in {"MESH", "EMPTY"}]
    mesh_objects = [obj for obj in asset_objects if obj.type == "MESH"]
    before_min, before_max = bounds(mesh_objects)
    before_dimensions = before_max - before_min
    scale_factor = 2.0 / before_dimensions.z
    roots = [obj for obj in asset_objects if obj.parent is None]
    for root in roots:
        root.scale *= scale_factor
    bpy.context.view_layer.update()
    scaled_min, _ = bounds(mesh_objects)
    floor_translation = -scaled_min.z
    for root in roots:
        root.location.z += floor_translation
    bpy.context.view_layer.update()

    bpy.ops.object.select_all(action="DESELECT")
    for obj in mesh_objects:
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        obj.select_set(False)
    if len(mesh_objects) == 1:
        mesh_objects[0].name = "material_dispenser"
        mesh_objects[0].data.name = "material_dispenser_mesh"
    for obj in mesh_objects:
        obj.data.materials.clear()
    clay = material("Evaluation_Clay", (0.36, 0.42, 0.45, 1.0), 0.72)
    for obj in mesh_objects:
        obj.data.materials.append(clay)

    bpy.ops.object.select_all(action="DESELECT")
    for obj in asset_objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = mesh_objects[0]
    bpy.ops.export_scene.gltf(
        filepath=str(output_glb),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
    )
    for obj in asset_objects:
        obj.select_set(False)

    after_min, after_max = bounds(mesh_objects)
    after_dimensions = after_max - after_min

    floor_mat = material("Evaluation_Floor", (0.16, 0.18, 0.19, 1.0), 0.85)
    bpy.ops.mesh.primitive_plane_add(size=12.0, location=(0.0, 0.0, 0.0))
    floor = bpy.context.object
    floor.name = "evaluation_floor"
    floor.data.materials.append(floor_mat)

    bpy.ops.object.camera_add(location=(3.6, -5.0, 2.8))
    camera = bpy.context.object
    camera.name = "evaluation_camera"
    camera.data.lens = 58
    bpy.context.scene.camera = camera

    world = bpy.context.scene.world or bpy.data.worlds.new("Evaluation_World")
    bpy.context.scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.055, 0.065, 0.07, 1.0)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.35

    bpy.ops.object.light_add(type="AREA", location=(3.5, -4.0, 5.0))
    key = bpy.context.object
    key.name = "key_light"
    key.data.energy = 900
    key.data.shape = "DISK"
    key.data.size = 4.0
    look_at(key, Vector((0.0, 0.0, 1.0)))
    bpy.ops.object.light_add(type="AREA", location=(-3.0, -1.0, 3.0))
    fill = bpy.context.object
    fill.name = "fill_light"
    fill.data.energy = 500
    fill.data.size = 3.0
    look_at(fill, Vector((0.0, 0.0, 1.0)))
    bpy.ops.object.light_add(type="AREA", location=(0.0, 3.0, 4.0))
    rim = bpy.context.object
    rim.name = "rim_light"
    rim.data.energy = 700
    rim.data.size = 2.5
    look_at(rim, Vector((0.0, 0.0, 1.2)))

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = 512
    scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    scene.render.image_settings.color_mode = "RGBA"
    target = Vector((0.0, 0.0, 1.0))
    views = {
        "front": Vector((0.0, -4.8, 1.55)),
        "left_side": Vector((4.8, 0.0, 1.55)),
        "back": Vector((0.0, 4.8, 1.55)),
        "front_three_quarter": Vector((3.8, -4.6, 2.8)),
    }
    for name, location in views.items():
        camera.location = location
        look_at(camera, target)
        scene.render.filepath = str(output_dir / f"{name}.png")
        bpy.ops.render.render(write_still=True)

    output_bytes = output_glb.read_bytes()
    operations = [
        "uniform scale to 2.0 m height",
        "align minimum Z to floor",
        "apply transforms",
        "assign shared evaluation clay material",
    ]
    if len(mesh_objects) == 1:
        operations.insert(3, "rename single mesh")
    evidence = {
        "input_path": str(input_path),
        "output_glb": str(output_glb),
        "input_dimensions": [round(v, 6) for v in before_dimensions],
        "scale_factor": round(scale_factor, 9),
        "floor_translation_after_scale": round(floor_translation, 9),
        "output_bounds_min": [round(v, 6) for v in after_min],
        "output_bounds_max": [round(v, 6) for v in after_max],
        "output_dimensions": [round(v, 6) for v in after_dimensions],
        "output_size_bytes": len(output_bytes),
        "output_sha256": hashlib.sha256(output_bytes).hexdigest(),
        "cleanup_operations": operations,
        "renders": {name: str(output_dir / f"{name}.png") for name in views},
    }
    (output_dir / "normalisation_evidence.json").write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(evidence))


if __name__ == "__main__":
    main()
