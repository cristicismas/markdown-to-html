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
	markdown_to_html("## This ```is``` an h2")
}

markdown_to_html :: proc(markdown: string) -> (html: string) {
	tokens := tokenize(markdown)

	return ""
}
