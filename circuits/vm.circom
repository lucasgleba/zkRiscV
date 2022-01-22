pragma circom 2.0.2;

// TODO: circom 2.0.3 [?]

include "./gates.circom";

template Operator(bits) {
    signal input a;
    signal input b;
    signal input opcode;
    signal output out;

    // TODO: Num2Bits vs Num2Bits_strict
    component aBits = Num2Bits(bits);
    component bBits = Num2Bits(bits);
    aBits.in <== a;
    bBits.in <== b;

    component mux = MultiMux4(bits);
    
    component add = BinSum(bits, 2);
    component sub = BinSub(bits);
    component xor = BitwiseXOR(bits);
    component or = BitwiseOR(bits);
    component and = BitwiseAND(bits);

    for (var ii = 0; ii < bits; ii++) {
        add.in[0][ii] <== aBits.out[ii];
        add.in[1][ii] <== bBits.out[ii];
        sub.in[0][ii] <== aBits.out[ii];
        sub.in[1][ii] <== bBits.out[ii];
        xor.in[0][ii] <== aBits.out[ii];
        xor.in[1][ii] <== bBits.out[ii];
        or.in[0][ii] <== aBits.out[ii];
        or.in[1][ii] <== bBits.out[ii];
        and.in[0][ii] <== aBits.out[ii];
        and.in[1][ii] <== bBits.out[ii];
    }
    
    for (var ii = 0; ii < bits; ii++) {
        mux.c[ii][0] <== add.out[ii];
        mux.c[ii][1] <== sub.out[ii];
        mux.c[ii][2] <== xor.out[ii];
        mux.c[ii][3] <== or.out[ii];
        mux.c[ii][4] <== and.out[ii];
    }

    for (var ii = 5; ii < 16; ii++) {
        for (var jj = 0; jj < bits; jj++) {
            mux.c[jj][ii] <== 0;
        }
    }

    component funcBits = Num2Bits(bits);
    funcBits.in <== opcode;

    for (var ii = 0; ii < 4; ii++) {
        mux.s[ii] <== funcBits.out[ii];
    }

    component outNum = Bits2Num(bits);

    for (var ii = 0; ii < bits; ii++) {
        outNum.in[ii] <==  mux.out[ii];
    }

    out <== outNum.out;

}

template ALU(bits) {
    signal input r1;
    signal input r2;
    signal input imm;
    signal input useImm;
    signal input pc;
    signal input opcode;
    signal output out;
    signal output pcOut;

    component op2 = Mux1();
    op2.c[0] <== r2;
    op2.c[1] <== imm;
    op2.s <== useImm;

    component operator = Operator(bits);
    operator.a <== r1;
    operator.b <== op2.out;
    operator.opcode <== opcode;

    out <== op2.out;
    pcOut <== pc + 1;

}
