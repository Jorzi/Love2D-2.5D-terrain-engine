import bpy
import json
from bpy_extras.io_utils import ImportHelper, ExportHelper
from mathutils import Vector

# Importer
def import_json(filepath):
    try:
        with open(filepath, 'r') as f:
            data = json.load(f)
            #print(data)
        frames = data.get("frames", [])
        metadata = data.get("meta", [])
        res = metadata.get("size", [])
        scale = 0.1
        for frame in frames:
            print(frame)
            z_coord = int(frame)
            quad = frames.get(frame).get("spriteSourceSize")
            x1 = quad.get("x")
            y1 = quad.get("y")
            x2 = x1 + quad.get("w")
            y2 = y1 + quad.get("h")
            verts = [
                Vector((x1 * scale, y1 * scale, z_coord * scale)),
                Vector((x1 * scale, y2 * scale, z_coord * scale)),
                Vector((x2 * scale, y2 * scale, z_coord * scale)),
                Vector((x2 * scale, y1 * scale, z_coord * scale)),
            ]
            edges = []
            faces = [[0, 1, 2, 3]]
            
            # Create mesh and object based on parsed data
            mesh = bpy.data.meshes.new("Imported Mesh")
            mesh.from_pydata(verts, [], faces)
            mesh.uv_layers.new(name="UVMap")
            mesh.update()
            uvQuad = frames.get(frame).get("frame")
            u1 = uvQuad.get("x") / metadata.get("size").get("w")
            v1 = uvQuad.get("y") / metadata.get("size").get("h")
            u2 = u1 + uvQuad.get("w") / metadata.get("size").get("w")
            v2 = v1 + uvQuad.get("h") / metadata.get("size").get("h")
            mesh.uv_layers.active.data[0].uv = (u1, v1)
            mesh.uv_layers.active.data[1].uv = (u1, v2)
            mesh.uv_layers.active.data[2].uv = (u2, v2)
            mesh.uv_layers.active.data[3].uv = (u2, v1)
            UVs = [
                Vector((u1, v1)),
                Vector((u1, v2)),
                Vector((u2, v2)),
                Vector((u2, v1)),
            ]
            # Create object
            obj = bpy.data.objects.new("Imported Object", mesh)

            # Link object to scene collection
            bpy.context.collection.objects.link(obj)

    except Exception as e:
        print("Error importing JSON file:", e)

class ImportJSON(bpy.types.Operator, ImportHelper):
    bl_idname = "import.my_json_format"
    bl_label = "Import My JSON"
    filename_ext = ".json"

    filter_glob: bpy.props.StringProperty(
        default="*.json",
        options={'HIDDEN'},
    )

    def execute(self, context):
        import_json(self.filepath)
        return {'FINISHED'}

def menu_func_import(self, context):
    self.layout.operator(ImportJSON.bl_idname, text="JSON (.json)")

# Exporter
def export_json(filepath, objects):
    data = {"vertices": [], "faces": []}

    for obj in objects:
        if obj.type == 'MESH':
            mesh = obj.data
            for vertex in mesh.vertices:
                data["vertices"].append(vertex.co[:])

            for face in mesh.polygons:
                face_indices = [v for v in face.vertices]
                data["faces"].append(face_indices)

    if not filepath.lower().endswith(".json"):
        filepath += ".json"

    with open(filepath, 'w') as f:
        json.dump(data, f, indent=4)

class ExportJSON(bpy.types.Operator, ExportHelper):
    bl_idname = "export.my_json_format"
    bl_label = "Export Selected Meshes to JSON"
    filename_ext = ".json"

    filter_glob: bpy.props.StringProperty(
        default="*.json",
        options={'HIDDEN'},
    )

    def execute(self, context):
        selected_objects = [obj for obj in bpy.context.selected_objects if obj.type == 'MESH']
        if not selected_objects:
            self.report({'ERROR'}, "No mesh objects selected")
            return {'CANCELLED'}

        export_json(self.filepath, selected_objects)
        self.report({'INFO'}, f"Exported {len(selected_objects)} mesh objects to {self.filepath}")
        return {'FINISHED'}

    def invoke(self, context, event):
        context.window_manager.fileselect_add(self)
        return {'RUNNING_MODAL'}

def menu_func_export(self, context):
    self.layout.operator(ExportJSON.bl_idname, text="JSON (.json)")

def register():
    bpy.utils.register_class(ImportJSON)
    bpy.types.TOPBAR_MT_file_import.append(menu_func_import)

    bpy.utils.register_class(ExportJSON)
    bpy.types.TOPBAR_MT_file_export.append(menu_func_export)

def unregister():
    bpy.utils.unregister_class(ImportJSON)
    bpy.types.TOPBAR_MT_file_import.remove(menu_func_import)

    bpy.utils.unregister_class(ExportJSON)
    bpy.types.TOPBAR_MT_file_export.remove(menu_func_export)

if __name__ == "__main__":
    register()