package main

import "core:fmt"
import t "tokenizer"

main :: proc() {
	input_string := "Here is a list: \n- first\n- second\n- third with __bold__\nList has ended!"
	tokens := t.tokenize(input_string)
	t.print_tokens(tokens, true)
}
