// https://github.com/tornadocash/tornado-core/blob/master/circuits/merkleTree.circom
pragma circom 2.0.2;

include "../../node_modules/circomlib/circuits/mimcsponge.circom";

// Computes MiMC([left, right])
template HashLeftRight() {
    signal input left;
    signal input right;
    signal output hash;

    component hasher = MiMCSponge(2, 220, 1);
    hasher.ins[0] <== left;
    hasher.ins[1] <== right;
    hasher.k <== 0;
    hash <== hasher.outs[0];
}

// if s == 0 returns [in[0], in[1]]
// if s == 1 returns [in[1], in[0]]
// TODO: is this a switch gate [?]
template DualMux() {
    signal input in[2];
    signal input s;
    signal output out[2];

    s * (1 - s) === 0;
    out[0] <== (in[1] - in[0])*s + in[0];
    out[1] <== (in[0] - in[1])*s + in[1];
}

template MerkleTree(levels) {
    signal input leaf;
    signal input pathElements[levels];
    signal input pathIndices[levels];
    signal output root;

    component selectors[levels];
    component hashers[levels];

    for (var ii = 0; ii < levels; ii++) {
        selectors[ii] = DualMux();
        selectors[ii].in[0] <== ii == 0 ? leaf : hashers[ii - 1].hash;
        selectors[ii].in[1] <== pathElements[ii];
        selectors[ii].s <== pathIndices[ii];

        hashers[ii] = HashLeftRight();
        hashers[ii].left <== selectors[ii].out[0];
        hashers[ii].right <== selectors[ii].out[1];
    }

    root <== hashers[levels - 1].hash;
}

// Verifies that merkle proof is correct for given merkle root and a leaf
// pathIndices input is an array of 0/1 selectors telling whether given pathElement is on the left or right side of merkle path
template MerkleTreeChecker(levels) {
    signal input leaf;
    signal input root;
    signal input pathElements[levels];
    signal input pathIndices[levels];

    component tree = MerkleTree(levels);
    tree.leaf <== leaf;
    for (var ii = 0; ii < levels; ii++) {
        tree.pathElements[ii] <== pathElements[ii];
        tree.pathIndices[ii] <== pathIndices[ii];
    }
    
    tree.root === root;
}