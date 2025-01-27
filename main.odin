package main

import "core:fmt"
import "core:reflect"
import "core:strings"
import "core:unicode/utf8"

Vector2 :: struct {
	x: u32,
	y: u32,
}

main :: proc() {
	input_string := "Here is a !\n[](! new line"
	markdown_to_html(input_string)
}

markdown_to_html :: proc(markdown: string) -> (html: string) {
	tokens := tokenize(markdown)

	return ""
}
