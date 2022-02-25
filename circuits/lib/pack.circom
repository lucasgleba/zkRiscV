pragma circom 2.0.2;

function getPackingVars(n, size) {
    var packingRatio = 253 \ size;
    var nPacks = n \ packingRatio;
    var rem = n % packingRatio;
    if (rem != 0) {
        nPacks += 1;
    }
    var vars[3] = [packingRatio, nPacks, rem];
    return vars;
}

template Pack(n, size) {
    var packingVars[3] = getPackingVars(n, size);
    var packingRatio = packingVars[0];
    var nPacks = packingVars[1];
    var rem = packingVars[2];

    // all rs have to be < 2 ** size
    signal input in[n];
    signal output out[nPacks];

    // TODO: can this be better [?]
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
        out[ii] <== result[ii][maxJJ - 1];
    }
}

// component main = Pack(32, 32);
