# Atramentum Luminis

Mod of some shaders of a popular game

## How to build

```sh
./build.sh alum # Or see script for other possible configurations.
```

## Tools

- `tools/shpk.py`: ShPk file manipulation tool, for extracting as well as building ;
- `tools/fix-3dm-hlsl.py`: Must be run on the unmodified output of [etnlGD/HLSLDecompiler](https://github.com/etnlGD/HLSLDecompiler). Applies various transforms to make the "decompile" easier to work with (fix of `swapc` opcode, conversion into pseudo-SSA, inlining, pattern matching).
