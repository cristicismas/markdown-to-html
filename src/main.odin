package main

import "core:fmt"
import "core:reflect"
import "core:strings"
import "core:unicode/utf8"
import t "tokenizer"

main :: proc() {
	input_string := "\n\ntitle example with __bold__ text"
	markdown_to_html(input_string)
}

ConversionState :: struct {
	in_bold:        bool,
	in_italic:      bool,
	in_bold_italic: bool,
	in_paragraph:   bool,
}

markdown_to_html :: proc(markdown: string) -> (html: string) {
	tokens := t.tokenize(markdown)

	return ""
}
