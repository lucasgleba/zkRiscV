const { buildMimcSponge } = require("circomlibjs");
const { getWasmTester } = require("./utils");

const N = 32;
const size = 32;

function packHash(data, hashFunc) {
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
  return hashFunc(packs);
}

describe("packHash", function () {
  let hashFunc;
  before(async function () {
    const mimcSponge = await buildMimcSponge();
    const key = 0;
    hashFunc = (arr) => mimcSponge.F.toString(mimcSponge.multiHash(arr, key), 10);
  });
  after(async () => {
    globalThis.curve_bn128.terminate();
  });
  it("ok", async function () {
    const circuit = await getWasmTester("packHash.test.circom");
    const data = new Array(N).fill(null);
    for (let ii = 0; ii < N; ii++) {
      data[ii] = ii + 1;
    }
    const w = await circuit.calculateWitness({ in: data }, true);
    const expected = packHash(data, hashFunc);
    await circuit.assertOut(w, { out: expected });
  });
});
