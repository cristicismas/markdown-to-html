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
	// TODO: handle "Here is a [](!"
	// TODO: handle "Here is a [empty link?]!"
	markdown_to_html("Here is a [](!")
}

markdown_to_html :: proc(markdown: string) -> (html: string) {
	tokens := tokenize(markdown)

	return ""
}
