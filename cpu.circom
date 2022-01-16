pragma circom 2.0.2;

include "./node_modules/circomlib/circuits/mux1.circom";
include "./node_modules/circomlib/circuits/mux4.circom";
include "./node_modules/circomlib/circuits/bitify.circom";

template Operand(bits) {
    signal input raw; // Two's complement
    signal input signed;
    signal output abs;
    signal output neg;
    var bitsPow = 2 ** bits;
    assert(raw < bitsPow);
    neg <== (raw \ 2 ** (bits - 1)) * signed;
    component mux = Mux1();
    mux.c[0] <== raw;
    mux.c[1] <== bitsPow - raw;
    mux.s <== neg;
    abs <== mux.out;
}

template Operate2(bits) {
    var functBits = 4;
    signal input op1Abs;
    signal input op1Neg;
    signal input op2Abs;
    signal input op2Neg;
    signal input funct;
    signal output out;
    var bitsPow = 2 ** bits;
    
    component selector = Num2Bits(functBits);
    selector.in <== funct;
    component mux4 = MultiMux4(2);

    for (var ii = 0; ii < functBits; ii++) {
        mux4.s[ii] <== selector.out[ii];
    }

    mux4.c[0][0] <== op1Abs + op2Abs; // ADD
    mux4.c[1][0] <== 0; // ADD NEG
    // mux4.c[0][1] <== 0; // SUB
    // mux4.c[0][2] <== op1Abs ^ op2Abs; // XOR
    // mux4.c[0][3] <== op1Abs | op2Abs; // OR
    // mux4.c[0][4] <== op1Abs & op2Abs; // AND
    // mux4.c[0][5] <== op1Abs * 2 ** op2Abs; // LEFT LOGICAL SHIFT
    // signal sfl;
    // sfl <== op1Abs >> op2Abs;
    // mux4.c[0][6] <== sfl; // RIGT LOGICAL SHIFT
    // mux4.c[0][7] <== sfl + (2 ** op2Abs - 1) * 2 ** (bits - op2Abs); // RIGT ARITH SHIFT
    // signal ltU;
    // ltU <==  rs1Abs < rs2Abs;
    // signal diffSign;
    // diffSign <== op1Neg + op2Neg - 2 * op1Neg * op2Neg;
    // mux4.c[0][8] <== diffSign * op1Neg + (1 - diffSign) * (ltU + op1Neg - 2 * ltU * op1Neg); // SET LESS THAN
    // mux4.c[0][9] <== ltU; // SET LESS THAN (U)
    // signal mul;
    // mul <== op1Abs * op2Abs;
    // signal mulHigh;
    // mulHigh <== mul >> bits;
    // mux4.c[0][10] <== mul; // MUL
    // mux4.c[1][10] <== diffSign; // MUL NEG
    // mux4.c[0][11] <== mulHigh; // MUL HIGH
    // mux4.c[1][11] <== diffSign; // MUL HIGH NEG
    // mux4.c[0][12] <== op1Abs \ op2Abs; // DIV
    // mux4.c[1][12] <== diffSign; // DIV NEG
    // mux4.c[1][13] <== op1Abs % op2Abs; // REMAINDER

    for (var ii = 1; ii < 2 ** functBits; ii++) {
        mux4.c[0][ii] <== 0;
        mux4.c[1][ii] <== 0;
    }

    signal resultRaw;
    resultRaw <== mux4.out[0];
    signal resultAbs;
    resultAbs <== resultRaw - (resultRaw \ bitsPow) * bitsPow;
    component signMux = Mux1();
    signMux.c[0] <== resultAbs;
    signMux.c[1] <== bitsPow - resultAbs;
    signMux.s <== mux4.out[1];
    out <== signMux.out;
}

template Execute(bits) {

    signal input rs1Raw;
    signal input rs1Signed;
    signal input rs2Raw;
    signal input rs2Signed;
    signal input immRaw;
    signal input immSigned;
    signal input useImm;
    signal input funct;
    signal input pcIn;
    signal output out;
    signal output pcOut;

    component op1 = Operand(bits);
    op1.raw <== rs1Raw;
    op1.signed <== rs1Signed;
    component op2r = Operand(bits);
    op2r.raw <== rs2Raw;
    op2r.signed <== rs2Signed;
    component op2imm = Operand(bits);
    op2imm.raw <== immRaw;
    op2imm.signed <== immSigned;

    component operate2 = Operate2(bits);
    operate2.op1Abs <== op1.abs;
    operate2.op1Neg <== op1.neg;

    component immMux = MultiMux1(2);
    immMux.c[0][0] <== op2r.abs;
    immMux.c[1][0] <== op2r.neg;
    immMux.c[0][1] <== op2imm.abs;
    immMux.c[1][1] <== op2imm.neg;
    immMux.s <== useImm;

    operate2.op2Abs <== immMux.out[0];
    operate2.op2Neg <== immMux.out[1];

    operate2.funct <== funct;

    out <== operate2.out;
    pcOut <== pcIn + 1;
}