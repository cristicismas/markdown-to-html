package main

import "core:fmt"
import "core:reflect"
import "core:strings"
import "core:unicode/utf8"
import t "tokenizer"

Vector2 :: struct {
	x: u32,
	y: u32,
}

main :: proc() {
	input_string := "Here is an escaped \\# H1 tag and an escaped \\\\ backwards slash."
	markdown_to_html(input_string)
}

markdown_to_html :: proc(markdown: string) -> (html: string) {
	tokens := t.tokenize(markdown)

	return ""
}
