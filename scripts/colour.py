bits = 4

with open("colours.mem", "wt") as file:
    for i in range(0, 2 ** bits):
        for j in range(0, 2 ** bits):
            for k in range(0, 2 ** bits):
                file.write(bytes([i, j, k]).hex()[1::2] + "\n")
