function sliceBin(str, start, end) {
  return str.slice(str.length - end, str.length - start);
}

function signExtend(str, size) {
  return str[0].repeat(size - str.length).concat(str);
}

function zeroExtend(str, size) {
  return "0".repeat(size - str.length).concat(str);
}

function twosCompToSign(value, size) {
  // TODO: check value is in range [?]
  if (value >= 2 ** (size - 1)) {
    return -(2 ** 32 - value);
  } else {
    return value;
  }
}

function fitTo32Bits(value) {
  const n = 2 ** 32;
  return ((value % n) + n) % n;
}

module.exports = {
  sliceBin,
  signExtend,
  zeroExtend,
  twosCompToSign,
  fitTo32Bits,
};
