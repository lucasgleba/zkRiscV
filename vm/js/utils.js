function sliceBin(str, start, end) {
  return str.slice(str.length - end, str.length - start);
}

function signExtend(str, size) {
  return str[0].repeat(size - str.length).concat(str);
}

function zeroExtend(str, size) {
  return "0".repeat(size - str.length).concat(str);
}

module.exports = {
  sliceBin,
  signExtend,
  zeroExtend,
};
