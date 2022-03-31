def write_data(path, data: bytes):
    with open(path, "wt") as bram_file:
        bram_file.write(data.hex("\n"))



if __name__ == "__main__":
    WIDTH = 640
    HEIGHT = 480
    data = bytes([i % 16 for i in range(WIDTH * HEIGHT)])
    print(len(data))
    write_data("bram_init.txt", data)
