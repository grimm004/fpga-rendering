import math

INT_W   = 16
FIXED_W = 16

def to_fixed_literal(n):
    data = []

    for i in range(INT_W - 1, -FIXED_W - 1, -1):
        p = 2 ** i
        if i == INT_W - 1:
            if n < 0:
                p = -p
            else:
                data.append(0)
                continue

        if n - p < 0:
            data.append(0)
        else:
            data.append(1)
            n -= p

    return f"32'b{''.join(map(str, data[:INT_W]))}_{''.join(map(str, data[INT_W:]))}"


def rotation_matrix_y(theta):
    return [
        [math.cos(theta), 0, -math.sin(theta), 0],
        [0, 1, 0, 0],
        [math.sin(theta), 0, math.cos(theta), 0],
        [0, 0, 0, 1]
    ]


def perspective_matrix(near, far, fov):
    s = 1.0 / (math.tan(fov * math.pi / 360.0))
    return [
        [s, 0, 0, 0],
        [0, s, 0, 0],
        [0, 0, -far / (far - near), -1],
        [0, 0, -far * near / (far - near), 0]
    ]


def dot(a, b):
    return sum([a[i] * b[i] for i in range(4)])


def vecmult(a, b):
    return [dot(a[i], b) for i in range(4)]


def matmult(a, b):
    return [[dot(a[row], [b[i][col] for i in range(4)]) for col in range(4)] for row in range(4)]


if __name__ == "__main__":
    import sys

    identity = [
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1]
    ]

    screen_space = [
        [640 / 2, 0, 0, 640 / 2],
        [0, -480 / 2, 0, 480 / 2],
        [0, 0, 1, 0],
        [0, 0, 0, 1]
    ]

    proj = perspective_matrix(0.5, 16.0, 90.0)

    mat = matmult(screen_space, matmult(proj, identity))

    vs = [
        [ 0.0,  0.5, -2.0, 1.0],
        [-0.5, -0.5, -2.0, 1.0],
        [ 0.5, -0.5, -2.0, 1.0]
    ]

    for v in vs:
        print(v, "->", vecmult(mat, v))

    theta = 2.0 * math.pi / (60.0 * 2.0)

    print(f"Radians: {theta}, Degrees: {180.0 * theta / math.pi}")

    rot = rotation_matrix_y(theta)

    # for i in range(120):
    #     identity = matmult(rot, identity)

    # print(identity)

    # sys.exit(0)
    
    values = [60, 20, 280, 80, 160, 164, 0, 0.5, -0.5, -2]
    for value in values:
        print(f"{value}:\nvalf value = {to_fixed_literal(value)};")

    matrices = {
        "identity": identity,
        "screen_space": screen_space,
        "rot": rot,
        "proj": proj
    }

    for name, matrix in matrices.items():
        output = f"mat4f {name} = " + "{\n"
        for i in range(len(matrix)):
            output += "    "
            for j in range(len(matrix[i])):
                output += f"{to_fixed_literal(matrix[i][j])}, "
            output += "\n"
        output = output[:-3]
        output += "\n};"
        
        print(output)

