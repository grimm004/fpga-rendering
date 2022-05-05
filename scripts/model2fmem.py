from fixedpoint import to_fixed


def obj_to_face_verts(obj_text):
    vertices = []
    faces    = []

    for line in obj_text.replace("\r", "").split("\n"):
        parts = line.strip().split()
        if not parts or parts[0] not in {"v", "f"}:
            continue

        if parts[0] == "v":
            vertices.append((list(map(float, parts[1:4])), [float(col) * 15 for col in parts[4:7]]))

        elif parts[0] == "f":
            faces.append([vertices[int(vert.split("/")[0]) - 1] for vert in parts[1:4]])

    print(len(faces))

    return faces


def obj_to_mem(obj_text):
    data_string = ""

    for i, face in enumerate(obj_to_face_verts(obj_text)):
        for j, vertex in enumerate(face):
            coords, col = vertex

            data_string += f"// Face {i + 1}, Vertex {j + 1}:\n// Coords\n"
 
            for dim_value in coords:
                data_fixed = to_fixed(dim_value)
                data_string += "".join(map(str, data_fixed)) + "\n"

            data_string += "// Col\n"

            for col_value in col:
                data_fixed = to_fixed(col_value)
                data_string += "".join(map(str, data_fixed)) + "\n"

            data_string += "\n"

    return data_string


if __name__ == "__main__":
    with open("cube.obj", "rt") as file:
        print(obj_to_mem(file.read()))
