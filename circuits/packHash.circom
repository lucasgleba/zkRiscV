pragma circom 2.0.2;

include "../node_modules/circomlib/circuits/mimcsponge.circom";

template PackHash(n, size) {
    // all rs have to be < 2 ** size
    signal input in[n];
    signal output out;
    // signal input hash;
    var packingRatio = 253 \ size;
    var nPacks = n \ packingRatio;
    var rem = n % packingRatio;
    if (rem != 0) {
        nPacks += 1;
    }
    // signal packs[nPacks];
    signal output packs[nPacks];
    signal result[nPacks][packingRatio];
    for (var ii = 0; ii < nPacks; ii++) {
        result[ii][0] <== in[ii * packingRatio];
        var maxJJ = packingRatio;
        if (ii == nPacks - 1 && rem != 0) {
            maxJJ = rem;
        }
        for (var jj = 1; jj < maxJJ; jj++) {
            result[ii][jj] <== result[ii][jj - 1] + in[ii * packingRatio + jj] * 2 ** (size * jj);
        }
        // for (var jj = maxJJ; jj < packingRatio; jj++) {
        //     result[ii][jj] <== 0;
        // }
        packs[ii] <== result[ii][maxJJ - 1];
    }
    component mimc = MiMCSponge(nPacks, 220, 1);
    for (var ii = 0; ii < nPacks; ii++) mimc.ins[ii] <== packs[ii];
    mimc.k <== 0;
    out <== mimc.outs[0];
}

template ValidPackHash(n, size) {
    signal input in[n];
    signal input hash;
    component packHash = PackHash(n, size);
    for (var ii = 0; ii < n; ii++) packHash.in[ii] <== in[ii];
    packHash.out === hash;
}

// component main = PackHash(33, 32);
