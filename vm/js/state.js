function fetchMemory(m, fetchSize, pointer) {
  let result = 0;
  for (let ii = 0; ii < fetchSize; ii++) {
    result += m[(pointer + ii) % m.length] * 2 ** (8 * ii);
  }
  return result;
}

function fetchRegister(r, address) {
  if (address == 0) {
    return 0;
  } else {
    return r[address - 1];
  }
}

function pack(data, size) {
  const packingRatio = Math.floor(253 / size);
  const nPacks = Math.ceil(data.length / packingRatio);
  const packs = new Array(nPacks).fill(null);
  const rem = data.length % packingRatio;
  for (let ii = 0; ii < nPacks; ii++) {
    let sum = BigInt(0);
    const maxJJ = ii == nPacks - 1 && rem > 0 ? rem : packingRatio;
    for (let jj = 0; jj < maxJJ; jj++) {
      sum +=
        BigInt(data[ii * packingRatio + jj]) * BigInt(2) ** BigInt(size * jj);
    }
    packs[ii] = sum;
  }
  return packs;
}

function hashState(state, hashFunc) {
  const packs = pack([state.pc, ...state.r, pack(state.m.slice(0, 4), 8)[0]], 32).concat(pack(state.m.slice(4, state.m.length), 8));
  return hashFunc(packs);
}

module.exports = {
  fetchMemory,
  fetchRegister,
  pack,
  hashState,
};
