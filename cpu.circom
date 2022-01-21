pragma circom 2.0.2;

include "./gates.circom";

template Operator(bits) {
    signal input a;
    signal input b;
    signal input funct;
    signal output out;

    // TODO: Num2Bits vs Num2Bits_strict
    component aBits = Num2Bits(bits);
    component bBits = Num2Bits(bits);
    aBits.in <== a;
    bBits.in <== b;

    component mux = MultiMux4(bits);
    component sum = BinSum(bits, 2);
    // component sub = BinSub(bits);

    for (var ii = 0; ii < bits; ii++) {
        sum.in[0][ii] <== aBits.out[ii];
        sum.in[1][ii] <== bBits.out[ii];
    }
    
    for (var ii = 0; ii < bits; ii++) {
        mux.c[ii][0] <== sum.out[ii];
    }

    for (var ii = 1; ii < 16; ii++) {
        for (var jj = 0; jj < bits; jj++) {
            mux.c[jj][ii] <== 0;
        }
    }

    component funcBits = Num2Bits(bits);
    funcBits.in <== funct;

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
    signal input funct;
    signal output out;
    signal output pcOut;

    component op2 = Mux1();
    op2.c[0] <== r2;
    op2.c[1] <== imm;
    op2.s <== useImm;

    component operator = Operator(bits);
    operator.a <== r1;
    operator.b <== op2.out;
    operator.funct <== funct;

    out <== op2.out;
    pcOut <== pc + 1;

}

component main = ALU(32);