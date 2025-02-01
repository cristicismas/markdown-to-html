package main

import "core:fmt"

main :: proc() {
	input_string := "paragraph #h1 heading example with __bold__ text"
	html := markdown_to_html(input_string)
	fmt.println("\n HTML: ", html)
}
