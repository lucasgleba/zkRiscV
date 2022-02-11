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

module.exports = {
  fetchMemory,
  fetchRegister,
};
