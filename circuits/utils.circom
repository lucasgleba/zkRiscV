pragma circom 2.0.2;

function signExtension (dataLength, wordLength) {
    return (2 ** (wordLength - dataLength) - 1) * 2 ** dataLength;
}