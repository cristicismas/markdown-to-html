package main

import "core:fmt"
import t "tokenizer"

main :: proc() {
	// input_string := "This is an ordered list:\n1. first\n2. second\n3. third\nlist has ended"
	input_string := "This is an ordered list:\n1. first\n2. second\n3. third\nlist has ended"
	html := markdown_to_html(input_string)
	fmt.println("html: ", html)
}
