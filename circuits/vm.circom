pragma circom 2.0.2;

// TODO: circom 2.0.3 [?]
// TODO: don't do with bin what you can do with dec

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
    component sub = BinSub(bits + 1);
    sub.in[0][bits] <== 0;
    sub.in[1][bits] <== 0;
    component xor = BitwiseXOR(bits);
    component or = BitwiseOR(bits);
    component and = BitwiseAND(bits);
    component sll = LeftShifter32(32);
    component srl = RightShifter32(32);
    component sra = RightShifter32(32);
    sll.k <== 0;
    srl.k <== 0;
    sra.k <== aBits.out[bits - 1];

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
        sll.in[0][ii] <== aBits.out[ii];
        sll.in[1][ii] <== bBits.out[ii];
        srl.in[0][ii] <== aBits.out[ii];
        srl.in[1][ii] <== bBits.out[ii];
        sra.in[0][ii] <== aBits.out[ii];
        sra.in[1][ii] <== bBits.out[ii];
    }

    for (var ii = 0; ii < bits; ii++) {
        mux.c[ii][0] <== add.out[ii];
        mux.c[ii][1] <== sub.out[ii];
        mux.c[ii][2] <== xor.out[ii];
        mux.c[ii][3] <== or.out[ii];
        mux.c[ii][4] <== and.out[ii];
        mux.c[ii][5] <== sll.out[ii];
        mux.c[ii][6] <== srl.out[ii];
        mux.c[ii][7] <== sra.out[ii];
    }

    mux.c[0][8] <== sub.out[bits - 1];
    mux.c[0][9] <== sub.out[bits];

    for (var ii = 1; ii < bits; ii++) {
        mux.c[ii][8] <== 0;
        mux.c[ii][9] <== 0;
    }

    for (var ii = 10; ii < 16; ii++) {
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

template ImmLoader(bits) {
    signal input imm;
    signal input pc;
    signal input opcode;
    signal output out;
    out <== (imm * 2**12) + pc * opcode;
}

template Jumper(bits) {
    signal input rs1;
    signal input imm;
    signal input pc;
    signal input opcode;
    signal output out;
    signal output pcOut;
    out <== pc + 1;
    component mux = Mux1();
    mux.c[0] <== pc + imm;
    mux.c[1] <== rs1 + imm;
    mux.s <== opcode;
    pcOut <== mux.out;
}

template Brancher(bits) {
    signal input cmp;
    signal input imm;
    signal input pc;
    signal input eq;
    signal output pcOut;
    component mux = Mux1();
    mux.c[0] <== pc + 1;
    mux.c[1] <== pc + imm;
    component zr = IsZero();
    zr.in <== cmp;
    mux.s <== zr.out * eq;
    pcOut <== mux.out;
}

template ALU(bits) {
    signal input r1;
    signal input r2;
    signal input imm;
    signal input useImm;
    signal input pc;
    signal input opcode1;
    signal input opcode2;
    signal output out;
    signal output pcOut;

    component op2 = Mux1();
    op2.c[0] <== r2;
    op2.c[1] <== imm;
    op2.s <== useImm;

    component operator = Operator(bits);
    operator.a <== r1;
    operator.b <== op2.out;
    operator.opcode <== opcode2;

    component immLoader = ImmLoader(bits);
    immLoader.imm <== imm;
    immLoader.pc <== pc;
    immLoader.opcode <== opcode2;

    component mux = Mux1();
    mux.c[0] <== operator.out;
    mux.c[1] <== immLoader.out;
    mux.s <== opcode1;

    out <== mux.out;
    pcOut <== pc + 1;

}
