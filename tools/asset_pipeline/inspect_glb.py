import bpy
import bmesh
import hashlib
import json
import os
import sys
from pathlib import Path
from mathutils import Vector


def script_args() -> list[str]:
    return sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []


def connected_components(mesh: bpy.types.Mesh) -> int:
    if not mesh.vertices:
        return 0
    adjacency: list[list[int]] = [[] for _ in mesh.vertices]
    for edge in mesh.edges:
        a, b = edge.vertices
        adjacency[a].append(b)
        adjacency[b].append(a)
    unseen = set(range(len(mesh.vertices)))
    count = 0
    while unseen:
        count += 1
        stack = [unseen.pop()]
        while stack:
            vertex = stack.pop()
            for neighbour in adjacency[vertex]:
                if neighbour in unseen:
                    unseen.remove(neighbour)
                    stack.append(neighbour)
    return count


def bmesh_components(bm: bmesh.types.BMesh) -> int:
    unseen = set(bm.verts)
    count = 0
    while unseen:
        count += 1
        stack = [unseen.pop()]
        while stack:
            vertex = stack.pop()
            for edge in vertex.link_edges:
                neighbour = edge.other_vert(vertex)
                if neighbour in unseen:
                    unseen.remove(neighbour)
                    stack.append(neighbour)
    return count


def vec(values) -> list[float]:
    return [round(float(value), 6) for value in values]


def main() -> None:
    args = script_args()
    if len(args) != 2:
        raise SystemExit("usage: blender --background --python inspect_glb.py -- input.glb output.json")
    input_path = Path(args[0]).resolve()
    output_path = Path(args[1]).resolve()

    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    bpy.ops.import_scene.gltf(filepath=str(input_path))

    objects = list(bpy.context.scene.objects)
    meshes = [obj for obj in objects if obj.type == "MESH"]
    corners: list[Vector] = []
    object_stats = []
    total_vertices = 0
    total_edges = 0
    total_polygons = 0
    total_triangles = 0
    total_non_manifold = 0
    total_raw_non_manifold = 0
    total_degenerate = 0
    total_components = 0
    total_welded_components = 0
    material_names: set[str] = set()

    for obj in meshes:
        mesh = obj.data
        mesh.calc_loop_triangles()
        vertices = len(mesh.vertices)
        edges = len(mesh.edges)
        polygons = len(mesh.polygons)
        triangles = len(mesh.loop_triangles)
        components = connected_components(mesh)
        degenerate = sum(1 for polygon in mesh.polygons if polygon.area <= 1.0e-12)
        bm = bmesh.new()
        bm.from_mesh(mesh)
        raw_non_manifold = sum(1 for edge in bm.edges if not edge.is_manifold)
        bmesh.ops.remove_doubles(bm, verts=list(bm.verts), dist=1.0e-6)
        bm.verts.ensure_lookup_table()
        bm.edges.ensure_lookup_table()
        non_manifold = sum(1 for edge in bm.edges if not edge.is_manifold)
        welded_components = bmesh_components(bm)
        welded_vertices = len(bm.verts)
        bm.free()
        for material in mesh.materials:
            if material is not None:
                material_names.add(material.name)
        for corner in obj.bound_box:
            corners.append(obj.matrix_world @ Vector(corner))
        total_vertices += vertices
        total_edges += edges
        total_polygons += polygons
        total_triangles += triangles
        total_non_manifold += non_manifold
        total_raw_non_manifold += raw_non_manifold
        total_degenerate += degenerate
        total_components += components
        total_welded_components += welded_components
        object_stats.append({
            "name": obj.name,
            "vertices": vertices,
            "edges": edges,
            "polygons": polygons,
            "triangles": triangles,
            "connected_components": components,
            "welded_connected_components": welded_components,
            "welded_vertices": welded_vertices,
            "raw_non_manifold_edges": raw_non_manifold,
            "non_manifold_edges": non_manifold,
            "degenerate_polygons": degenerate,
            "location": vec(obj.location),
            "rotation_euler": vec(obj.rotation_euler),
            "scale": vec(obj.scale),
            "dimensions": vec(obj.dimensions),
            "materials": [material.name for material in mesh.materials if material is not None],
        })

    if corners:
        minimum = Vector((min(point.x for point in corners), min(point.y for point in corners), min(point.z for point in corners)))
        maximum = Vector((max(point.x for point in corners), max(point.y for point in corners), max(point.z for point in corners)))
    else:
        minimum = Vector((0.0, 0.0, 0.0))
        maximum = Vector((0.0, 0.0, 0.0))

    data = input_path.read_bytes()
    evidence = {
        "blender_version": bpy.app.version_string,
        "input_path": str(input_path),
        "file_size_bytes": len(data),
        "sha256": hashlib.sha256(data).hexdigest(),
        "object_count": len(objects),
        "mesh_count": len(meshes),
        "objects": object_stats,
        "total_vertices": total_vertices,
        "total_edges": total_edges,
        "total_polygons": total_polygons,
        "total_triangles": total_triangles,
        "total_connected_components": total_components,
        "total_welded_connected_components": total_welded_components,
        "total_raw_non_manifold_edges": total_raw_non_manifold,
        "total_non_manifold_edges": total_non_manifold,
        "total_degenerate_polygons": total_degenerate,
        "material_names": sorted(material_names),
        "bounds_min": vec(minimum),
        "bounds_max": vec(maximum),
        "dimensions": vec(maximum - minimum),
        "floor_offset": round(float(minimum.z), 6),
        "root_objects": [
            {
                "name": obj.name,
                "type": obj.type,
                "location": vec(obj.location),
                "rotation_euler": vec(obj.rotation_euler),
                "scale": vec(obj.scale),
            }
            for obj in objects if obj.parent is None
        ],
    }
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(evidence, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({
        "output": str(output_path),
        "triangles": total_triangles,
        "non_manifold_edges": total_non_manifold,
        "dimensions": evidence["dimensions"],
    }))


if __name__ == "__main__":
    main()
