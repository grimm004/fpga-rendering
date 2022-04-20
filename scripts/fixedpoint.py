import math

INT_W   = 16
FIXED_W = 16


def graidients(v0, v1, v2):
    temp = (v0[0] - v2[0]) * (v1[1] - v2[1]) - 0
    temp = (v1[0] - v2[0]) * (v0[1] - v2[1]) - temp
    dx = temp

    print("dx", dx)
    
    one_over_dx = 1.0 / dx;
    one_over_dy = -one_over_dx

    print("reciprocals", one_over_dx, one_over_dy)

    x_step = (((v1[2] - v2[2]) * (v0[1] - v2[1])) - ((v0[2] - v2[2]) * (v1[1] - v2[1]))) * one_over_dx;
    y_step = (((v1[2] - v2[2]) * (v0[0] - v2[0])) - ((v0[2] - v2[2]) * (v1[0] - v2[0]))) * one_over_dy;

    return x_step, y_step


def fixed_str_to_dec(s):
    return fixed_to_dec([int(bc) for bc in s.replace("_", "")])


def fixed_to_dec(bits):
    j = 0
    n = 0
    for i in range(INT_W - 1, -FIXED_W - 1, -1):
        p = 2 ** i
        if j == 0:
            p = -p
        n += bits[j] * p
        j += 1
    return n


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


def scale_matrix(x, y, z):
    return [
        [x, 0, 0, 0],
        [0, y, 0, 0],
        [0, 0, z, 0],
        [0, 0, 0, 1]
    ]


def translation_matrix(x, y, z):
    return [
        [1, 0, 0, x],
        [0, 1, 0, y],
        [0, 0, 1, z],
        [0, 0, 0, 1]
    ]


def rotation_matrix_y(theta):
    return [
        [math.cos(theta), 0, -math.sin(theta), 0],
        [0,               1,  0,               0],
        [math.sin(theta), 0,  math.cos(theta), 0],
        [0,               0,  0,               1]
    ]


def perspective_matrix(fov, width, height, z_near, z_far):
    aspect_ratio = width / height
    z_range = z_near - z_far
    tan_half_fov = math.tan(fov * math.pi / 360.0)
    return [
        [1.0 / (tan_half_fov * aspect_ratio), 0,                   0,                           0],
        [0,                                   1.0 / tan_half_fov,  0,                           0],
        [0,                                   0,                   (-z_near - z_far) / z_range, 2 * z_far * z_near / z_range],
        [0,                                   0,                   1,  0]
    ]


def dot(a, b):
    return sum([a[i] * b[i] for i in range(4)])


def vecmult(a, b):
    return [dot(a[i], b) for i in range(4)]


def matmult(a, b):
    return [[dot(a[row], [b[i][col] for i in range(4)]) for col in range(4)] for row in range(4)]


def perspective_divide(a):
    recip = 1.0 / a[3]
    return [a[0] * recip, a[1] * recip, a[2] * recip, a[3]]

if __name__ == "__main__":
    import sys

    vs = [
        [320.0, 160.0, 0xF],
        [240.0, 320.0, 0x0],
        [400.0, 320.0, 0x0]
    ]

    dz_dx, dz_dy = graidients(vs[0], vs[1], vs[2])
    print("Gradients:", dz_dx, dz_dy)

    # sys.exit()

    print(fixed_str_to_dec("0000000000000001_0000000000000000"))
    print(fixed_str_to_dec("1111111111111101_1110111101111011"))
    print(fixed_str_to_dec("1111111100010000_0000000000000000"))

    identity = [
        [1, 0, 0, 0],
        [0, 1, 0, 0],
        [0, 0, 1, 0],
        [0, 0, 0, 1]
    ]

    screen_space = [
        [640 / 2,  0,       0, 640 / 2],
        [0,       -480 / 2, 0, 480 / 2],
        [0,        0,       1, 0      ],
        [0,        0,       0, 1      ]
    ]

    proj = perspective_matrix(90.0, 640, 480, 1.0, 32.0)

    translation = translation_matrix(0.0, 0.0, 3.0)
    
    rot = rotation_matrix_y(315 * math.pi / 60.0)
    print(rot)

    rot_mat = identity
    #for _ in range(30):
    #    rot_mat = matmult(rot, rot_mat)

    mat = matmult(screen_space, matmult(proj, matmult(translation, rot_mat)))

    print(mat)

    vs = [
        [ 0.0,  1.0, 0.0, 1.0],
        [-1.0, -1.0, 0.0, 1.0],
        [ 1.0, -1.0, 0.0, 1.0]
    ]

    for v in vs:
        v_transformed = vecmult(mat, v)
        print(v, "->", [float(f"{p:.2f}") for p in v_transformed], "->", [float(f"{p:.2f}") for p in perspective_divide(v_transformed)])

    values = [320.0, 160.0, 240.0, 320.0, 400.0, 320.0, -180, 180]
    for value in values:
        print(f"{value}:\nvalf value = {to_fixed_literal(value)};")

    matrices = {
        "identity": identity,
        "screen_space": screen_space,
        "rot": rot,
        "proj": proj,
        "translation": translation,
        "mat": mat
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

    sys.exit(0)

