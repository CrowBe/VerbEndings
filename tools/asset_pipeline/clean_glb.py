import bpy
import bmesh
import hashlib
import json
import sys
from pathlib import Path


values = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
if len(values) != 3:
    raise SystemExit(
        "usage: blender --background --python clean_glb.py -- "
        "input.glb output.glb evidence.json"
    )
input_path, output_path, evidence_path = [Path(value).resolve() for value in values]

bpy.ops.object.select_all(action="SELECT")
bpy.ops.object.delete(use_global=False)
bpy.ops.import_scene.gltf(filepath=str(input_path))
mesh_objects = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
before_triangles = 0
after_triangles = 0
removed_faces = 0
per_object = []

for obj in mesh_objects:
    mesh = obj.data
    mesh.calc_loop_triangles()
    before = len(mesh.loop_triangles)
    before_triangles += before

    bm = bmesh.new()
    bm.from_mesh(mesh)
    tiny_faces = [face for face in bm.faces if face.calc_area() < 1.0e-6]
    collapse_edges = {
        min(face.edges, key=lambda edge: edge.calc_length())
        for face in tiny_faces
        if face.edges
    }
    if collapse_edges:
        bmesh.ops.collapse(bm, edges=list(collapse_edges))
    bmesh.ops.dissolve_degenerate(bm, edges=list(bm.edges), dist=1.0e-7)
    bmesh.ops.recalc_face_normals(bm, faces=list(bm.faces))
    bm.to_mesh(mesh)
    bm.free()

    mesh.validate(verbose=False, clean_customdata=True)
    mesh.update(calc_edges=True)
    mesh.calc_loop_triangles()
    after = len(mesh.loop_triangles)
    after_triangles += after
    removed_faces += max(0, before - after)
    per_object.append({
        "name": obj.name,
        "triangles_before": before,
        "triangles_after": after,
    })

bpy.ops.object.select_all(action="SELECT")
output_path.parent.mkdir(parents=True, exist_ok=True)
bpy.ops.export_scene.gltf(
    filepath=str(output_path),
    export_format="GLB",
    use_selection=True,
    export_apply=True,
    export_yup=True,
)
output_data = output_path.read_bytes()
evidence = {
    "input_path": str(input_path),
    "output_path": str(output_path),
    "operation": (
        "collapse the shortest edge of faces below 1e-6 square metres, "
        "dissolve edges shorter than 1e-7 m, recalculate face normals, "
        "validate mesh data, and export with applied transforms"
    ),
    "mesh_count": len(mesh_objects),
    "triangles_before": before_triangles,
    "triangles_after": after_triangles,
    "triangles_removed": removed_faces,
    "output_size_bytes": len(output_data),
    "output_sha256": hashlib.sha256(output_data).hexdigest(),
    "objects": per_object,
}
evidence_path.parent.mkdir(parents=True, exist_ok=True)
evidence_path.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
print(json.dumps({
    key: evidence[key]
    for key in [
        "triangles_before",
        "triangles_after",
        "triangles_removed",
        "output_size_bytes",
        "output_sha256",
    ]
}))
