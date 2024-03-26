module regfile (
    input logic clk,
    input logic we1,
    we2,
    input logic [5:0] a1,
    a2,
    aw1,
    aw2,
    input logic [31:0] wd1,
    wd2,
    output logic [31:0] rd1,
    rd2
);

  initial cell0 = 32'h00000000;
  initial cell1 = 32'hDEADBEEF;
  initial cell2 = 32'h00400000;

  logic [31:0]
      cell0,
      cell1,
      cell2,
      cell3,
      cell4,
      cell5,
      cell6,
      cell7,
      cell8,
      cell9,
      cell10,
      cell11,
      cell12,
      cell13,
      cell14,
      cell15,
      cell16,
      cell17,
      cell18,
      cell19,
      cell20,
      cell21,
      cell22,
      cell23,
      cell24,
      cell25,
      cell26,
      cell27,
      cell28,
      cell29,
      cell30,
      cell31,
      cell32,
      cell33,
      cell34,
      cell35,
      cell36,
      cell37,
      cell38,
      cell39,
      cell40,
      cell41,
      cell42,
      cell43,
      cell44,
      cell45,
      cell46,
      cell47,
      cell48,
      cell49,
      cell50,
      cell51,
      cell52,
      cell53,
      cell54,
      cell55,
      cell56,
      cell57,
      cell58,
      cell59,
      cell60,
      cell61,
      cell62,
      cell63;

  always @(posedge clk) begin
    if (aw1 == 0 & we1) cell0 <= wd1;
    else if (aw2 == 0 & we2) cell0 <= wd2;
    if (aw1 == 1 & we1) cell1 <= wd1;
    else if (aw2 == 1 & we2) cell1 <= wd2;
    if (aw1 == 2 & we1) cell2 <= wd1;
    else if (aw2 == 2 & we2) cell2 <= wd2;
    if (aw1 == 3 & we1) cell3 <= wd1;
    else if (aw2 == 3 & we2) cell3 <= wd2;
    if (aw1 == 4 & we1) cell4 <= wd1;
    else if (aw2 == 4 & we2) cell4 <= wd2;
    if (aw1 == 5 & we1) cell5 <= wd1;
    else if (aw2 == 5 & we2) cell5 <= wd2;
    if (aw1 == 6 & we1) cell6 <= wd1;
    else if (aw2 == 6 & we2) cell6 <= wd2;
    if (aw1 == 7 & we1) cell7 <= wd1;
    else if (aw2 == 7 & we2) cell7 <= wd2;
    if (aw1 == 8 & we1) cell8 <= wd1;
    else if (aw2 == 8 & we2) cell8 <= wd2;
    if (aw1 == 9 & we1) cell9 <= wd1;
    else if (aw2 == 9 & we2) cell9 <= wd2;
    if (aw1 == 10 & we1) cell10 <= wd1;
    else if (aw2 == 10 & we2) cell10 <= wd2;
    if (aw1 == 11 & we1) cell11 <= wd1;
    else if (aw2 == 11 & we2) cell11 <= wd2;
    if (aw1 == 12 & we1) cell12 <= wd1;
    else if (aw2 == 12 & we2) cell12 <= wd2;
    if (aw1 == 13 & we1) cell13 <= wd1;
    else if (aw2 == 13 & we2) cell13 <= wd2;
    if (aw1 == 14 & we1) cell14 <= wd1;
    else if (aw2 == 14 & we2) cell14 <= wd2;
    if (aw1 == 15 & we1) cell15 <= wd1;
    else if (aw2 == 15 & we2) cell15 <= wd2;
    if (aw1 == 16 & we1) cell16 <= wd1;
    else if (aw2 == 16 & we2) cell16 <= wd2;
    if (aw1 == 17 & we1) cell17 <= wd1;
    else if (aw2 == 17 & we2) cell17 <= wd2;
    if (aw1 == 18 & we1) cell18 <= wd1;
    else if (aw2 == 18 & we2) cell18 <= wd2;
    if (aw1 == 19 & we1) cell19 <= wd1;
    else if (aw2 == 19 & we2) cell19 <= wd2;
    if (aw1 == 20 & we1) cell20 <= wd1;
    else if (aw2 == 20 & we2) cell20 <= wd2;
    if (aw1 == 21 & we1) cell21 <= wd1;
    else if (aw2 == 21 & we2) cell21 <= wd2;
    if (aw1 == 22 & we1) cell22 <= wd1;
    else if (aw2 == 22 & we2) cell22 <= wd2;
    if (aw1 == 23 & we1) cell23 <= wd1;
    else if (aw2 == 23 & we2) cell23 <= wd2;
    if (aw1 == 24 & we1) cell24 <= wd1;
    else if (aw2 == 24 & we2) cell24 <= wd2;
    if (aw1 == 25 & we1) cell25 <= wd1;
    else if (aw2 == 25 & we2) cell25 <= wd2;
    if (aw1 == 26 & we1) cell26 <= wd1;
    else if (aw2 == 26 & we2) cell26 <= wd2;
    if (aw1 == 27 & we1) cell27 <= wd1;
    else if (aw2 == 27 & we2) cell27 <= wd2;
    if (aw1 == 28 & we1) cell28 <= wd1;
    else if (aw2 == 28 & we2) cell28 <= wd2;
    if (aw1 == 29 & we1) cell29 <= wd1;
    else if (aw2 == 29 & we2) cell29 <= wd2;
    if (aw1 == 30 & we1) cell30 <= wd1;
    else if (aw2 == 30 & we2) cell30 <= wd2;
    if (aw1 == 31 & we1) cell31 <= wd1;
    else if (aw2 == 31 & we2) cell31 <= wd2;
    if (aw1 == 32 & we1) cell32 <= wd1;
    else if (aw2 == 32 & we2) cell32 <= wd2;
    if (aw1 == 33 & we1) cell33 <= wd1;
    else if (aw2 == 33 & we2) cell33 <= wd2;
    if (aw1 == 34 & we1) cell34 <= wd1;
    else if (aw2 == 34 & we2) cell34 <= wd2;
    if (aw1 == 35 & we1) cell35 <= wd1;
    else if (aw2 == 35 & we2) cell35 <= wd2;
    if (aw1 == 36 & we1) cell36 <= wd1;
    else if (aw2 == 36 & we2) cell36 <= wd2;
    if (aw1 == 37 & we1) cell37 <= wd1;
    else if (aw2 == 37 & we2) cell37 <= wd2;
    if (aw1 == 38 & we1) cell38 <= wd1;
    else if (aw2 == 38 & we2) cell38 <= wd2;
    if (aw1 == 39 & we1) cell39 <= wd1;
    else if (aw2 == 39 & we2) cell39 <= wd2;
    if (aw1 == 40 & we1) cell40 <= wd1;
    else if (aw2 == 40 & we2) cell40 <= wd2;
    if (aw1 == 41 & we1) cell41 <= wd1;
    else if (aw2 == 41 & we2) cell41 <= wd2;
    if (aw1 == 42 & we1) cell42 <= wd1;
    else if (aw2 == 42 & we2) cell42 <= wd2;
    if (aw1 == 43 & we1) cell43 <= wd1;
    else if (aw2 == 43 & we2) cell43 <= wd2;
    if (aw1 == 44 & we1) cell44 <= wd1;
    else if (aw2 == 44 & we2) cell44 <= wd2;
    if (aw1 == 45 & we1) cell45 <= wd1;
    else if (aw2 == 45 & we2) cell45 <= wd2;
    if (aw1 == 46 & we1) cell46 <= wd1;
    else if (aw2 == 46 & we2) cell46 <= wd2;
    if (aw1 == 47 & we1) cell47 <= wd1;
    else if (aw2 == 47 & we2) cell47 <= wd2;
    if (aw1 == 48 & we1) cell48 <= wd1;
    else if (aw2 == 48 & we2) cell48 <= wd2;
    if (aw1 == 49 & we1) cell49 <= wd1;
    else if (aw2 == 49 & we2) cell49 <= wd2;
    if (aw1 == 50 & we1) cell50 <= wd1;
    else if (aw2 == 50 & we2) cell50 <= wd2;
    if (aw1 == 51 & we1) cell51 <= wd1;
    else if (aw2 == 51 & we2) cell51 <= wd2;
    if (aw1 == 52 & we1) cell52 <= wd1;
    else if (aw2 == 52 & we2) cell52 <= wd2;
    if (aw1 == 53 & we1) cell53 <= wd1;
    else if (aw2 == 53 & we2) cell53 <= wd2;
    if (aw1 == 54 & we1) cell54 <= wd1;
    else if (aw2 == 54 & we2) cell54 <= wd2;
    if (aw1 == 55 & we1) cell55 <= wd1;
    else if (aw2 == 55 & we2) cell55 <= wd2;
    if (aw1 == 56 & we1) cell56 <= wd1;
    else if (aw2 == 56 & we2) cell56 <= wd2;
    if (aw1 == 57 & we1) cell57 <= wd1;
    else if (aw2 == 57 & we2) cell57 <= wd2;
    if (aw1 == 58 & we1) cell58 <= wd1;
    else if (aw2 == 58 & we2) cell58 <= wd2;
    if (aw1 == 59 & we1) cell59 <= wd1;
    else if (aw2 == 59 & we2) cell59 <= wd2;
    if (aw1 == 60 & we1) cell60 <= wd1;
    else if (aw2 == 60 & we2) cell60 <= wd2;
    if (aw1 == 61 & we1) cell61 <= wd1;
    else if (aw2 == 61 & we2) cell61 <= wd2;
    if (aw1 == 62 & we1) cell62 <= wd1;
    else if (aw2 == 62 & we2) cell62 <= wd2;
    if (aw1 == 63 & we1) cell63 <= wd1;
    else if (aw2 == 63 & we2) cell63 <= wd2;
  end

  logic [31:0] rd1_tmp, rd2_tmp;
  assign rd1_tmp = 
    a1[5] ? 
      a1[4] ? 
        a1[3] ? 
          a1[2] ? a1[1] ? a1[0] ? cell63 : cell62 : a1[0] ? cell61 : cell60 : a1[1] ? a1[0] ? cell59 : cell58 : a1[0] ? cell57 : cell56:
          a1[2] ? a1[1] ? a1[0] ? cell55 : cell54 : a1[0] ? cell53 : cell52 : a1[1] ? a1[0] ? cell51 : cell50 : a1[0] ? cell49 : cell48:
        a1[3] ? 
          a1[2] ? a1[1] ? a1[0] ? cell47 : cell46 : a1[0] ? cell45 : cell44 : a1[1] ? a1[0] ? cell43 : cell42 : a1[0] ? cell41 : cell40:
          a1[2] ? a1[1] ? a1[0] ? cell39 : cell38 : a1[0] ? cell37 : cell36 : a1[1] ? a1[0] ? cell35 : cell34 : a1[0] ? cell33 : cell32:
      a1[4] ?
        a1[3] ? 
          a1[2] ? a1[1] ? a1[0] ? cell31 : cell30 : a1[0] ? cell29 : cell28 : a1[1] ? a1[0] ? cell27 : cell26 : a1[0] ? cell25 : cell24:
          a1[2] ? a1[1] ? a1[0] ? cell23 : cell22 : a1[0] ? cell21 : cell20 : a1[1] ? a1[0] ? cell19 : cell18 : a1[0] ? cell17 : cell16:
        a1[3] ? 
          a1[2] ? a1[1] ? a1[0] ? cell15 : cell14 : a1[0] ? cell13 : cell12 : a1[1] ? a1[0] ? cell11 : cell10 : a1[0] ? cell9 : cell8:
          a1[2] ? a1[1] ? a1[0] ? cell7 : cell6 : a1[0] ? cell5 : cell4 : a1[1] ? a1[0] ? cell3 : cell2 : a1[0] ? cell1 : cell0;
  assign rd2_tmp =
    a2[5] ?
      a2[4] ?
        a2[3] ?
          a2[2] ? a2[1] ? a2[0] ? cell63 : cell62 : a2[0] ? cell61 : cell60 : a2[1] ? a2[0] ? cell59 : cell58 : a2[0] ? cell57 : cell56:
          a2[2] ? a2[1] ? a2[0] ? cell55 : cell54 : a2[0] ? cell53 : cell52 : a2[1] ? a2[0] ? cell51 : cell50 : a2[0] ? cell49 : cell48:
        a2[3] ?
          a2[2] ? a2[1] ? a2[0] ? cell47 : cell46 : a2[0] ? cell45 : cell44 : a2[1] ? a2[0] ? cell43 : cell42 : a2[0] ? cell41 : cell40:
          a2[2] ? a2[1] ? a2[0] ? cell39 : cell38 : a2[0] ? cell37 : cell36 : a2[1] ? a2[0] ? cell35 : cell34 : a2[0] ? cell33 : cell32:
      a2[4] ?
        a2[3] ?
          a2[2] ? a2[1] ? a2[0] ? cell31 : cell30 : a2[0] ? cell29 : cell28 : a2[1] ? a2[0] ? cell27 : cell26 : a2[0] ? cell25 : cell24:
          a2[2] ? a2[1] ? a2[0] ? cell23 : cell22 : a2[0] ? cell21 : cell20 : a2[1] ? a2[0] ? cell19 : cell18 : a2[0] ? cell17 : cell16:
        a2[3] ?
          a2[2] ? a2[1] ? a2[0] ? cell15 : cell14 : a2[0] ? cell13 : cell12 : a2[1] ? a2[0] ? cell11 : cell10 : a2[0] ? cell9 : cell8:
          a2[2] ? a2[1] ? a2[0] ? cell7 : cell6 : a2[0] ? cell5 : cell4 : a2[1] ? a2[0] ? cell3 : cell2 : a2[0] ? cell1 : cell0;

  assign rd1 = (a1 == aw1 & we1) ? wd1 : (a1 == aw2 & we2) ? wd2 : rd1_tmp;
  assign rd2 = (a2 == aw1 & we1) ? wd1 : (a2 == aw2 & we2) ? wd2 : rd2_tmp;

endmodule
