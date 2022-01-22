function Operator(bits) {
  self = this;
  bits = bits || 32;
  maxValueP1 = 2 ** bits;
  this.rawOps = {
    add: (aa, bb) => aa + bb,
    sub: (aa, bb) => aa - bb,
    xor: (aa, bb) => aa ^ bb,
    or: (aa, bb) => aa | bb,
    and: (aa, bb) => aa & bb,
  };
  this.fitToBits = function (value) {
    value = value % maxValueP1;
    return value < 0 ? maxValueP1 + value : value;
  };
  this.opWrapper = function (op) {
    function wrapped() {
      return self.fitToBits(op(...arguments));
    }
    return wrapped;
  };
  this.ops = {};
  for (const key in this.rawOps) {
    this.ops[key] = this.opWrapper(this.rawOps[key]);
  }
  this.opNamesByCode = {
    0: "add",
    1: "sub",
    2: "xor",
    3: "or",
    4: "and",
  };
  this.opsByCode = {};
  this.opcodes = {};
  for (const opcode in this.opNamesByCode) {
    const opName = this.opNamesByCode[opcode];
    this.opsByCode[opcode] = this.ops[opName];
    this.opcodes[opName] = opcode;
  }
  this.execute = function (aa, bb, opcode) {
    const op = this.opsByCode[opcode];
    if (op == undefined) {
      throw "opcode not valid";
    }
    return op(aa, bb);
  };
}

module.exports = {
  Operator
}