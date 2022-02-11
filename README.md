Name ideas:
- Jellyfish
- Medusa
- Squid
- Kraken

Testing arch
- Implement VM in js in parts and test circom circuits separately and end-to-end in single and multiple steps.
- Test js machine end to end against output of fast rv32im emulator.
    - (Then, port the emulator to wasm.)

Notes:
- Feb 7, 2022: When using non-merkleized memory, does it make sense to distinguishing between memory and registers? (other than for RISC-V compatibility)
    - Could put it all in the same array and save some load/stores.
    - Would not be possible to address registers with a 5-bit address.

Constrains in ValidVMStep_Flat(n); mSize = 128 (Harvard): 2235 * n + 3960 * 2
Can fit 465 VM steps in 2^20 constraints.

Constrains in ValidVMStep_Flat(n); mSize = 128 (Harvard): 4780 * n + 7920;
Can fit 217 VM steps in 2^20 constraints.
Can fit 56156 VM steps in 2^28 constraints.
