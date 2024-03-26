module mux2 #(
    parameter WIDTH = 8
) (
    input logic [WIDTH-1:0] d0,
    d1,
    input logic s,
    output logic [WIDTH -1:0] y
);
  assign y = s ? d1 : d0;
endmodule

module mux3 #(
    parameter WIDTH = 8
) (
    input logic [WIDTH - 1:0] d0,
    d1,
    d2,
    input logic [1:0] s,
    output logic [WIDTH - 1:0] y
);
  assign y = s[1] ? (s[0] ? d2 : d1) : d0;
endmodule

module mux5 #(
    parameter WIDTH = 8
) (
    input logic [WIDTH - 1:0] d0,
    d1,
    d2,
    d3,
    d4,
    input logic [2:0] s,
    output logic [WIDTH - 1:0] y
);
  assign y = s[2] ? d4 : s[1] ? s[0] ? d3 : d2 : s[0] ? d1 : d0;
endmodule

module mux6 #(
    parameter WIDTH = 8
) (
    input logic [WIDTH - 1:0] d0,
    d1,
    d2,
    d3,
    d4,
    d5,
    input logic [2:0] s,
    output logic [WIDTH - 1:0] y
);
  assign y = s[2] ? s[0] ? d5 : d4 : s[1] ? s[0] ? d3 : d2 : s[0] ? d1 : d0;
endmodule
