package main

import "core:fmt"
import t "tokenizer"

main :: proc() {
	input_string := "```This is a \ncode block\nwith multiple\nlines```"
	html := markdown_to_html(input_string)
	fmt.println("html: ", html)
}
