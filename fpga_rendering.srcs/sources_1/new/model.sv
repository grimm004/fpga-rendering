`default_nettype none
`timescale 1ns / 1ps

import Utils::vec3f;

module model (
    input  wire logic clk,
    input  wire logic reset,
    input  wire logic face_start,
    output      vec3f v0, v1, v2,
    output      vec3f c0, c1, c2,
    output      logic face_done,
    output      logic busy,
    output      logic done
    );

    localparam FACE_COUNT = 12;
    localparam VERT_COUNT = 3;

    localparam ROM_WIDTH = 2 * VERT_COUNT * 32; // pos and col for each verte
    localparam ROM_DEPTH = FACE_COUNT;
    localparam ROM_FILE  = "cube.mem";

    logic [$clog2(ROM_DEPTH):0] rom_addr;
    logic signed [ROM_WIDTH-1:0] rom_data [ROM_DEPTH];

    initial begin
        if (ROM_FILE != 0) begin
            $display("Creating model rom from init file '%s'.", ROM_FILE);
            $readmemb(ROM_FILE, rom_data);
        end
    end

    enum {IDLE, FACE_READ, FACE_DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                rom_addr     <= 0;
                face_done    <= 0;
                busy         <= 0;
                done         <= 0;

                if (face_start) begin
                    state <= FACE_READ;
                    busy <= 1;
                end
            end
            FACE_READ: begin
                {v0, v1, v2, c0, c1, c2} <= rom_data[rom_addr];
                face_done <= 1;
                state <= FACE_DONE;
            end
            FACE_DONE: begin
                busy <= 0;
                face_done <= 0;

                if (rom_addr == ROM_DEPTH) begin
                    state <= IDLE;
                    done <= 1;
                end else if (face_start) begin
                    rom_addr <= rom_addr + 1;
                    busy <= 1;
                    state <= FACE_READ;
                end
            end
        endcase

        if (reset)
            state <= IDLE;
    end

endmodule
