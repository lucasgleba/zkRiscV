// will error for big fetchSize as it uses normal numbers instead of BigInts
function fetchMemory(m, fetchSize, pointer) {
    let result = 0;
    for (let ii = 0; ii < fetchSize; ii++) {
        result += m[(pointer + ii) % m.length] * 2 ** (8 * ii);
    }
    return result;
}

module.exports = {
    fetchMemory,
}