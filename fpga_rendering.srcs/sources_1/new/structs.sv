`default_nettype none
`timescale 1ns / 1ps

`define CHANW   4
`define INTW    16
`define FRACW   16

package Utils;
    typedef logic [`CHANW-1:0] chani;
    typedef logic signed [`INTW-1:0] vali;
    typedef logic signed [`INTW-1:-`FRACW] valf;

    typedef struct packed {
        chani r, g, b;
    } coli;

    typedef struct packed {
        vali x, y;
        coli   col;
    } vert;

    typedef struct packed {
        vali x, y, z, w;
    } vec4i;

    typedef struct packed {
        valf x, y, z, w;
    } vec4f;

    typedef struct packed {
        vali x, y;
        chani c;
    } vert2i;

    typedef struct packed {
        vali
            v11, v12, v13, v14,
            v21, v22, v23, v24,
            v31, v32, v33, v34,
            v41, v42, v43, v44;
    } mat4i;

    typedef struct packed {
        valf
            v11, v12, v13, v14,
            v21, v22, v23, v24,
            v31, v32, v33, v34,
            v41, v42, v43, v44;
    } mat4f;
endpackage: Utils