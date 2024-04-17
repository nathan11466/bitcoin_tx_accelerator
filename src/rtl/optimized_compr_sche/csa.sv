module csa #(parameter dim = 32)
            (X, Y, Z, S, C);

input [dim-1 : 0] X, Y, Z;
output [dim-1 : 0] S, C;

genvar i;
generate
    for (i = 0; i < dim; i = i + 1) begin
        assign (S[i], C[i]) = (X[i] ^ Y[i] ^ Z[i], (X[i] & Y[i]) | (Y[i] & Z[i]) | (Z[i] & X[i]));
    end
endgenerate

endmodule
