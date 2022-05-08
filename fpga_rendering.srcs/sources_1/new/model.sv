`default_nettype none
`timescale 1ns / 1ps

import Utils::valf;
import Utils::vec3f;
import Utils::colf;

module model #(
    parameter FACE_COUNT=12,
    parameter FILE=""
    ) (
    input  wire logic clk,
    input  wire logic reset,
    input  wire logic face_start,
    output      vec3f v0, v1, v2,
    output      colf  c0, c1, c2,
    output      logic face_done,
    output      logic busy,
    output      logic complete,
    output      logic done
    );

    localparam VERTS_PER_FACE = 3;
    localparam DIMS_PER_VERT = 3;
    localparam CHANS_PER_VERT = 3;
    localparam BITS_PER_VAL = 32;
    localparam VALS_PER_FACE = (DIMS_PER_VERT + CHANS_PER_VERT) * VERTS_PER_FACE;

    valf current_face [0:VALS_PER_FACE-1];

    localparam ROM_WIDTH = BITS_PER_VAL;
    localparam ROM_DEPTH = VALS_PER_FACE * FACE_COUNT;

    logic [$clog2(ROM_DEPTH):0] rom_addr;
    logic signed [ROM_WIDTH-1:0] rom_data [ROM_DEPTH];

    initial begin
        if (FILE != 0) begin
            $display("Creating model rom from init file '%s'.", FILE);
            $readmemb(FILE, rom_data);
        end
    end

    logic [$clog2(VALS_PER_FACE):0] i;

    enum {IDLE, INIT_FACE, VAL_READ, VERT_DONE, FACE_DONE} state;
    always_ff @(posedge clk) begin
        case (state)
            IDLE: begin
                i            <= 0;
                rom_addr     <= 0;
                face_done    <= 0;
                busy         <= 0;
                done         <= 0;

                state <= INIT_FACE;
            end
            INIT_FACE: begin
                face_done <= 0;
                busy <= 0;

                if (rom_addr == ROM_DEPTH) begin
                    state <= IDLE;
                    done <= 1;
                    complete <= 1;
                end else if (face_start) begin
                    complete <= 0;
                    busy <= 1;
                    state <= VAL_READ;
                end
            end
            VAL_READ: begin
                current_face[i] <= rom_data[rom_addr];
                rom_addr <= rom_addr + 1;

                if (i == VALS_PER_FACE - 1) begin
                    state <= FACE_DONE;
                    i <= 0;
                end else
                    i <= i + 1;
            end
            FACE_DONE: begin
                face_done <= 1;

                v0 = {current_face[0],  current_face[1],  current_face[2]};
                c0 = {current_face[3],  current_face[4],  current_face[5]};
                v1 = {current_face[6],  current_face[7],  current_face[8]};
                c1 = {current_face[9],  current_face[10], current_face[11]};
                v2 = {current_face[12], current_face[13], current_face[14]};
                c2 = {current_face[15], current_face[16], current_face[17]};

                state <= INIT_FACE;
            end
        endcase

        if (reset)
            state <= IDLE;
    end

endmodule
