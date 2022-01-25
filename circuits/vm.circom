pragma circom 2.0.2;

// TODO: circom 2.0.3 [?]
// TODO: don't do with bin what you can do with dec
// TODO: optimize
// TODO: size-limit pc, out [?]
// TODO: computator instead of operator [?]
// TODO: add constrains for input size [?]
// TODO: break things into smaller components
// TODO: cost of mux?
// TODO: use constants instead of hard-coding
// TODO: more consistent naming
// TODO: brute force efficient circuits [?]
// TODO: order the SPAGET
// TODO: binequals template

include "./gates.circom";

template Operator(bits) {
    signal input a;
    signal input b;
    signal input pc;
    signal input opcode;
    signal output out;
    signal output pcOut;

    pcOut <== pc + 4;

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
        mux.c[ii][8] <== sub.out[ii];
        mux.c[ii][4] <== xor.out[ii];
        mux.c[ii][6] <== or.out[ii];
        mux.c[ii][7] <== and.out[ii];
        mux.c[ii][1] <== sll.out[ii];
        mux.c[ii][5] <== srl.out[ii];
        mux.c[ii][12] <== sra.out[ii];
    }

    mux.c[0][2] <== sub.out[bits - 1];
    mux.c[0][3] <== sub.out[bits];

    for (var ii = 1; ii < bits; ii++) {
        mux.c[ii][2] <== 0;
        mux.c[ii][3] <== 0;
    }

    for (var ii = 9; ii < 12; ii++) {
        for (var jj = 0; jj < bits; jj++) {
            mux.c[jj][ii] <== 0;
        }
    }
    
    for (var ii = 13; ii < 16; ii++) {
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
    signal output pcOut;
    pcOut <== pc + 4;
    out <== imm + pc * (1 - opcode);
}

template Jumper(bits) {
    signal input rs1;
    signal input imm;
    signal input pc;
    signal input opcode;
    signal output out;
    signal output pcOut;
    out <== pc + 4;
    component mux = Mux1();
    mux.c[0] <== rs1 + imm; // jalr
    mux.c[1] <== pc + imm; // jal
    mux.s <== opcode;
    pcOut <== mux.out;
}

template Brancher(bits) {
    signal input cmp;
    signal input imm;
    signal input pc;
    signal input neq;
    signal output out;
    signal output pcOut;
    out <== 0;
    component mux = Mux1();
    mux.c[0] <== pc + 4;
    mux.c[1] <== pc + imm; // [?]
    component zr = IsZero();
    zr.in <== cmp;
    component xor = XOR();
    xor.a <== zr.out;
    xor.b <== neq;
    mux.s <== xor.out;
    pcOut <== mux.out;
}

template ALU(bits) {
    signal input rs1;
    signal input rs2;
    signal input imm;
    signal input useImm;
    signal input pc;
    signal input insOpcode;
    signal input funcOpcode;
    signal input neqOpcode;
    signal output out;
    signal output pcOut;

    component op2 = Mux1();
    op2.c[0] <== rs2;
    op2.c[1] <== imm;
    op2.s <== useImm;

    component operator = Operator(bits);
    operator.a <== rs1;
    operator.b <== op2.out;
    operator.pc <== pc;
    operator.opcode <== funcOpcode;

    component immLoader = ImmLoader(bits);
    immLoader.imm <== imm;
    immLoader.pc <== pc;
    immLoader.opcode <== funcOpcode;
    
    component jumper = Jumper(bits);
    jumper.rs1 <== rs1;
    jumper.imm <== imm;
    jumper.pc <== pc;
    jumper.opcode <== funcOpcode;
    
    component brancher = Brancher(bits);
    brancher.cmp <== operator.out;
    brancher.imm <== imm;
    brancher.pc <== pc;
    brancher.neq <== neqOpcode;

    component insOpcodeBits = Num2Bits(2);
    insOpcodeBits.in <== insOpcode;

    component iMux = MultiMux2(2);
    iMux.c[0][0] <== operator.out;
    iMux.c[1][0] <== operator.pcOut;
    iMux.c[0][1] <== immLoader.out;
    iMux.c[1][1] <== immLoader.pcOut;
    iMux.c[0][2] <== jumper.out;
    iMux.c[1][2] <== jumper.pcOut;
    iMux.c[0][3] <== brancher.out;
    iMux.c[1][3] <== brancher.pcOut;
    for (var ii = 0; ii < 2; ii++) {
        iMux.s[ii] <== insOpcodeBits.out[ii];
    }

    out <== iMux.out[0];
    pcOut <== iMux.out[1];

}

/*
R operate-r 0110011 51  12  6   3   1   0
I operate-i 0010011 19  4   2   1   0   0
I load      0000011 3   0   0   0   0   0
S store     0100011 35  8   4   2   1   0
B branch    1100011 99  24  12  6   3   1
J jal       1101111 111 27  13  6   3   1
I jalr      1100111 103 25  12  6   3   1
U lui       0110111 55  13  6   3   1   0
U auipc     0010111 23  5   2   1   0   0

I load      00000
I operate-i 00100
S store     01000
R operate-r 01100
            02200

U lui       01101
U auipc     00101
            01202

B branch    11000
I jalr      11001
            22001

J jal       11011

            36414

R 0
I 1
U 2
B 3
J 4
S 5

R operate-r 01100
            01100

I operate-i 00100
I jalr      11001
I load      00000
            xxx0x

S store     01000
B branch    11000
            x1000

J jal       11011
U lui       01101
U auipc     00101
            xxxx1
*/

function signExtension (dataLength, wordLength) {
    return (2 ** (wordLength - dataLength) - 1) * 2 ** dataLength;
}

template InsDecoder() {
    signal input ins;
    signal output rd; // ok
    signal output rs1; // ok
    signal output rs2; // ok
    signal output imm; // ok
    signal output useImm; // ok
    // TODO: rename these
    signal output insOpcode; // almost ok
    signal output funcOpcode;
    signal output neqOpcode; // ok
    signal output rOpcode; // ok
    signal output storeOpcode; // ok

    // ins to bin
    component insBin = Num2Bits(32);
    insBin.in <== ins;

    // get ins type
    component r_sMux = MultiMux1(2);
    component rs_iMux = MultiMux1(2);
    component u_rsiMux = MultiMux1(2);
    component ib_ursiMux = MultiMux1(2);
    component i_bMux = MultiMux1(2);
    component j_ibursiMux = MultiMux1(2);

    r_sMux.s <== insBin.out[2 + 2];
    rs_iMux.s <== insBin.out[3 + 2];
    u_rsiMux.s <== insBin.out[0 + 2];
    ib_ursiMux.s <== insBin.out[4 + 2];
    i_bMux.s <== insBin.out[0 + 2];
    j_ibursiMux.s <== insBin.out[1 + 2];
    
    r_sMux.c[0][0] <== 2; // s
    r_sMux.c[1][0] <== signExtension(7, 32); // s
    
    r_sMux.c[0][1] <== 0; // r
    r_sMux.c[1][1] <== 0; // r
    
    rs_iMux.c[0][0] <== 1; // i
    rs_iMux.c[1][0] <== signExtension(12, 32); // i
    
    rs_iMux.c[0][1] <== r_sMux.out[0]; // rs
    rs_iMux.c[1][1] <== r_sMux.out[1]; // rs
    
    u_rsiMux.c[0][0] <== rs_iMux.out[0]; // rsi
    u_rsiMux.c[1][0] <== rs_iMux.out[1]; // rsi
    
    u_rsiMux.c[0][1] <== 4; // u
    u_rsiMux.c[1][1] <== 0; // u
    
    i_bMux.c[0][0] <== 3; // b
    i_bMux.c[1][0] <== signExtension(13, 32); // b
    
    i_bMux.c[0][1] <== 1; // i
    i_bMux.c[1][1] <== signExtension(12, 32); // i
    
    ib_ursiMux.c[0][0] <== u_rsiMux.out[0]; // ursi
    ib_ursiMux.c[1][0] <== u_rsiMux.out[1]; // ursi
    
    ib_ursiMux.c[0][1] <== i_bMux.out[0]; // ib
    ib_ursiMux.c[1][1] <== i_bMux.out[1]; // ib
    
    j_ibursiMux.c[0][0] <== ib_ursiMux.out[0]; // ibursi
    j_ibursiMux.c[1][0] <== ib_ursiMux.out[1]; // ibursi
    
    j_ibursiMux.c[0][1] <== 5; // j
    j_ibursiMux.c[1][1] <== signExtension(20, 32); // j

    component insTypeBin = Num2Bits(3);
    insTypeBin.in <== j_ibursiMux.out[0];

    component rs1Num = Bits2Num(5);
    component rs2Num = Bits2Num(5);
    component rdNum = Bits2Num(5);
    for (var ii = 0; ii < 5; ii++) {
        rs1Num.in[ii] <== insBin.out[15 + ii];
        rs2Num.in[ii] <== insBin.out[20 + ii];
        rdNum.in[ii] <== insBin.out[7 + ii];
    }

    // set easy outputs
    rs1 <== rs1Num.out;
    rs2 <== rs2Num.out;
    rd <== rdNum.out * (1 - insTypeBin.out[1]);
    useImm <== 1 - insBin.out[5];
    neqOpcode <== insBin.out[12];
    rOpcode <== insBin.out[4] + insBin.out[6];
    storeOpcode <== insBin.out[5];

    // set imm

    component immINum = Bits2Num(12);
    component immSBNum = Bits2Num(12);
    component immUJNum = Bits2Num(20);

    for (var ii = 0; ii < 12; ii++) {
        immINum.in[ii] <== insBin.out[20 + ii];
    }
    for (var ii = 0; ii < 5; ii++) {
        immSBNum.in[ii] <== insBin.out[7 + ii];
    }
    for (var ii = 0; ii < 7; ii++) {
        immSBNum.in[5 + ii] <== insBin.out[25 + ii];
    }
    for (var ii = 0; ii < 20; ii++) {
        immUJNum.in[ii] <== insBin.out[12 + ii];
    }
    
    component sb_iImmMux = Mux1();
    component uj_sbiImmMux = Mux1();

    sb_iImmMux.c[0] <== immINum.out;
    sb_iImmMux.c[1] <== immSBNum.out;
    sb_iImmMux.s <== insTypeBin.out[1];

    uj_sbiImmMux.c[0] <== sb_iImmMux.out;
    uj_sbiImmMux.c[1] <== immUJNum.out;
    uj_sbiImmMux.s <== insTypeBin.out[2];

    signal rawImm;
    rawImm <== uj_sbiImmMux.out + j_ibursiMux.out[1] * insBin.out[31]; // mux imm sign extended

    component s12_rawImmMux = Mux1();
    component s1_12rImmMux = Mux1();
    s12_rawImmMux.c[0] <== rawImm;
    s12_rawImmMux.c[1] <== rawImm * 2 ** 12;
    s12_rawImmMux.s <== insTypeBin.out[2];
    s1_12rImmMux.c[0] <== s12_rawImmMux.out;
    s1_12rImmMux.c[1] <== rawImm * 2;
    component immOr = OR();
    immOr.a <== insTypeBin.out[0] * insTypeBin.out[1];
    immOr.b <== insTypeBin.out[0] * insTypeBin.out[2];
    s1_12rImmMux.s <== immOr.out;

    imm <== s1_12rImmMux.out;
    // imm <== rawImm;

    // set insOpcode

    /*
    1   0
    01100 0
    00100 0
    11000 3
    11011 2
    11001 2
    01101 1
    00101 1
    =====
    [2] +  2*[1] + [0]*[2] + [0]*[1]
    000 0
    001 0
    011 3
    100 1
    101 2
    =====

    000 0 0
    001 0->0/1-> 2
    011 1 3
    100 0 1
    101 1 2
    
    s * 2 + [1] + [2] * (1 - [0]) TODO: try to simplify
    000 0 0 ok
    001 0 0 ok
    001 1 2 ok
    011 1 3 ok
    100 0 1 ok
    101 1 2 ok
    */

    // insOpcode <== insBin.out[6] * 2 + insTypeBin.out[1] + insTypeBin.out[2] * (1 - insTypeBin.out[0]);
    insOpcode <== insBin.out[6] * 2 + insTypeBin.out[1] + insTypeBin.out[2] * (1 - insTypeBin.out[0]);
    
    // set funcOpcode

    component f3Num = Bits2Num(3);
    for (var ii = 0; ii < 3; ii++) {
        f3Num.in[ii] <== insBin.out[12 + ii];
    }

    component insOpBin = Num2Bits(2);
    insOpBin.in <== insOpcode;
    
    component riIncMux = Mux1();

    component quickAnd = AND();
    quickAnd.a <== insBin.out[12 + 2];
    quickAnd.b <== 1 - insBin.out[12 + 1];

    riIncMux.c[0] <== 1;
    riIncMux.c[1] <== quickAnd.out * insBin.out[12 + 0];
    riIncMux.s <== insTypeBin.out[0];

    component funcMux = Mux2();
    funcMux.c[0] <== f3Num.out + 8 * insBin.out[30] * riIncMux.out;
    funcMux.c[1] <== insBin.out[5];
    funcMux.c[2] <== insBin.out[3];
    funcMux.c[3] <== 8 - 6 * insBin.out[25 + 2] + insBin.out[25 + 1];
    funcMux.s[0] <== insOpBin.out[0];
    funcMux.s[1] <== insOpBin.out[1];
    funcOpcode <== funcMux.out;

}

// component main = InsDecoder();

/*
000 0
001 1
100 0
101 1
110 0
111 1

0 f3 + f7[5] * 8
1 opcode[5]
2 opcode[3]
3

add 0x0
sub 0x0 + 0x8
xor 0x4
or 0x6
and 0x7
sll 0x1
srl 0x5
sra 0x5 + 0x8
slt 0x2
sltu 0x3

8 - 6 * [2] + [1]

0000 sub 0x8
0001 sub 0x8
0100 slt 0x2
0101 slt 0x2
0110 sltu 0x3
0111 sltu 0x3

0x20 = 00100000
0x5 = 101

000
001
010
011
100
101
110
111

[2] * (1 - [1]) * [0]

*/