# Markdown to HTML convertor and tokenizer

This project is supposed to support UTF8 files and tokens.

So far, only the UTF-8 compatible tokenizer is done. Conversion part is still WIP.

## Compiling locally

To run compile this locally, you need to install the latest version of the odin compiler and its dependencies: [https://odin-lang.org/docs/install/](https://odin-lang.org/docs/install/)

Then you can make use of the 2 shell scripts in the repo's root directory:

`./run.sh` -> runs the main.odin file in the src/ directory, outputting the binary in the bin/ directory

`./test.sh` -> runs the tests for the tokenizer package, then the main package, outputting the binaries in the bin/ directory

