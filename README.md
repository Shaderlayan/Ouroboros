# Ouroboros

Reverse engineering of some shaders of a popular game

## How to build

```sh
./build.sh
```
\- or -
```sh
./configure.py
make -j4 # Adjust to the number of parallel compiles you want to run.
```

## Tools

- `tools/shpk.py`: ShPk file manipulation tool, for extracting as well as building ;
- `tools/fix-3dm-hlsl.py`: Must be run on the unmodified output of [etnlGD/HLSLDecompiler][hlsldec]. Applies various transforms to make the "decompile" easier to work with (fix of `swapc` opcode, conversion into pseudo-SSA, inlining, pattern matching).
- `tools/extract-defs.py`: Must be run on a directory of outputs of [etnlGD/HLSLDecompiler][hlsldec]. Extracts structures, constant buffers and samplers definitions, to help write headers.

[hlsldec]: https://github.com/etnlGD/HLSLDecompiler
