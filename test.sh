echo "--- TOKENIZER TESTS: ---"
odin test src/tokenizer -out:bin/test

echo "--- MAIN TESTS: ---"
odin test src/ -out:bin/test
