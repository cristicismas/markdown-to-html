package main

import "core:fmt"
import "core:testing"

@(test)
empty_string_test :: proc(t: ^testing.T) {
	markdown := ""
	html := markdown_to_html(markdown)

	testing.expect(t, html == "")
}

@(test)
simple_h1_test :: proc(t: ^testing.T) {
	markdown := "# Simple h1 test"
	html := markdown_to_html(markdown)

	testing.expect(t, html == "<h1>Simple h1 test</h1>")
}

@(test)
tokenize_h1_test :: proc(t: ^testing.T) {
	input_string := "# h1 tokenize test"
	tokens := tokenize(input_string)

	expected_tokens: [2]Token = {
		{line = 1, type = TokenType.HASH_1},
		{line = 1, type = TokenType.TEXT, content = "h1 tokenize test"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

compare_token_slices :: proc(first: []Token, second: []Token) -> (are_equal: bool) {
	if len(first) != len(second) {
		fmt.eprintln("ERROR: Slice lenghts are not equal")
	}

	for token, i in first {
		if second[i] != token {
			return false
		}
	}

	return true
}
