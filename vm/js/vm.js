function opDicts(ops, opNamesByCode) {
  opsByCode = {};
  opcodes = {};
  for (const opcode in opNamesByCode) {
    const opName = opNamesByCode[opcode];
    opsByCode[opcode] = ops[opName];
    opcodes[opName] = opcode;
  }
  return [opsByCode, opcodes];
}

function Operator(bits) {
  self = this;
  bits = bits || 32;
  maxValueP1 = 2 ** bits;
  this._rawOps = {
    add: (aa, bb) => aa + bb,
    sub: (aa, bb) => aa - bb,
    xor: (aa, bb) => aa ^ bb,
    or: (aa, bb) => aa | bb,
    and: (aa, bb) => aa & bb,
    sll: (aa, bb) => aa << bb,
    srl: (aa, bb) => aa >>> bb,
    sra: (aa, bb) => aa >> bb,
    slt: (aa, bb) => this._toSigned(aa) < this._toSigned(bb) ? 1 : 0,
    sltu: (aa, bb) => aa < bb ? 1 : 0,
  };
  this._fitToBits = function (value) {
    value = value % maxValueP1;
    return value < 0 ? maxValueP1 + value : value;
  };
  this._toSigned = function (value) {
    if (value >= maxValueP1 / 2) {
      return maxValueP1 - value;
    } else {
      return value;
    }
  }
  this._opWrapper = function (op) {
    function wrapped() {
      return self._fitToBits(op(...arguments));
    }
    return wrapped;
  };
  this.ops = {};
  for (const key in this._rawOps) {
    this.ops[key] = this._opWrapper(this._rawOps[key]);
  }
  this.opNamesByCode = {
    0: "add",
    1: "sub",
    2: "xor",
    3: "or",
    4: "and",
    5: "sll",
    6: "srl",
    7: "sra",
    8: "slt",
    9: "sltu",
  };
  [this.opsByCode, this.opcodes] = opDicts(this.ops, this.opNamesByCode);
  // aa, bb are two's complement if negative
  this.execute = function (opcode, aa, bb) {
    const op = this.opsByCode[opcode];
    if (op == undefined) {
      throw "opcode not valid";
    }
    return op(aa, bb);
  };
}

function ImmLoader(bits) {
  bits = bits || 32;
  maxValueP1 = 2 ** bits;
  this.ops = {
    lui: (imm, pc) => imm << 12,
    auipc: (imm, pc) => pc + (imm << 12),
  };
  this.opNamesByCode = {
    0: "lui",
    1: "auipc",
  };
  [this.opsByCode, this.opcodes] = opDicts(this.ops, this.opNamesByCode);
  this.execute = function (opcode, imm, pc) {
    const op = this.opsByCode[opcode];
    if (op == undefined) {
      throw "opcode not valid";
    }
    return op(imm, pc);
  };
}

module.exports = {
  Operator,
  ImmLoader,
};