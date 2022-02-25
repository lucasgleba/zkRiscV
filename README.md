# zkSubleq

A zero-knowledge VM based on the rv32i Risc-V instruction set with almost full compatibility.

Generate zk-SNARKS proving that N steps of a program where executed correctly.

```
git clone https://github.com/lucasgleba/zkRiscV.git
cd zkRiscV
npm install
cd circuits
npx mocha # might take up to a minute
```

You will need [circom](https://github.com/iden3/circom) and [snarkjs](https://github.com/iden3/snarkjs) to compile circuits and generate proofs. Check out the [circom introduction](https://docs.circom.io/getting-started/installation/).

Check out [zkSubleq](https://github.com/lucasgleba/zkSubleq) for a similar project with a way simpler instruction set.

**RV32I?**

RV32I is a reduced instruction set architecture of the Risc-V family. It has 31 general purpose registers x1-x31 which hold 32-bit integer values and a zero register x0 which is hardwired to 0.
- https://riscv.org/
- https://github.com/riscv

## How does it work?

Instruction decoding and logical/arithmetic operations are a bit intricate but straightforward to implement. The trickiest and most costly part is state reading and writing.

The state consists of the program counter, the registers, and memory.

The program counter and registers are always passed as signals as they are very small. The code includes two approaches for handling memory:

- Flat memory: The entirety of memory is passed as signals from one VM step to the other just like the registers. Reads and writes are done with multiplexers and inverse multiplexers respectively. This is a simple and effective approach when the size of the memory required is very small. The code includes an implementation for 128 byte memory array with half dedicated to program memory.

- Tree memory: Memory is held in a Merkle tree. Instead of passing the entirety of memory, you pass a Merkle proof for the section of memory being accessed in each step. Validating Merkel proofs is expensive but the size of the proofs scales logarithmically with the memory size. This makes this approach better suited for programs that require lots of memory.

## RV32I compatibility

zkRiscV supports all the instructions in the instruction set except for multi-byte memory load/store and environment calls. Transpilation is straightforward (not implemented yet [transpiler/](transpiler/)).

## See also

One can use more sophisticated zero-knowledge math to make a much more efficient (but complex) zkVM. Most of the efforts in this front are being made by teams working on EVM-compatible zero-knowledge rollups.

- [Polygon Hermez](https://blog.hermez.io/zkevm-documentation/)
- [Starkware's Cairo](https://www.cairo-lang.org/hello-cairo/)
- [zkSync's zkEVM](https://docs.zksync.io/zkevm)

Ping me on [twitter](https://twitter.com/lucasgleba) if you want to learn more.