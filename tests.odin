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
tokenize_h1_test :: proc(t: ^testing.T) {
	input_string := "# h1 tokenize test"
	tokens := tokenize(input_string)

	expected_tokens: [2]Token = {
		{line = 1, type = TokenType.HASH_1},
		{line = 1, type = TokenType.TEXT, content = " h1 tokenize test"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_link_simple_test :: proc(t: ^testing.T) {
	input_string := "Here is a [link](https://www.google.com)!"
	tokens := tokenize(input_string)

	expected_tokens: [3]Token = {
		{line = 1, type = TokenType.TEXT, content = "Here is a "},
		{line = 1, type = TokenType.LINK, content = "link", link = "https://www.google.com"},
		{line = 1, type = TokenType.TEXT, content = "!"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_link_empty_test :: proc(t: ^testing.T) {
	input_string := "Here is an empty link []()!"
	tokens := tokenize(input_string)

	expected_tokens: [3]Token = {
		{line = 1, type = TokenType.TEXT, content = "Here is an empty link "},
		{line = 1, type = TokenType.LINK, content = "", link = ""},
		{line = 1, type = TokenType.TEXT, content = "!"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_invalid_link :: proc(t: ^testing.T) {
	input_string := "Here is a [](!"
	tokens := tokenize(input_string)

	expected_token: Token = {
		line    = 1,
		type    = TokenType.TEXT,
		content = "Here is a [](!",
	}

	testing.expect(t, expected_token == tokens[0])
}

@(test)
tokenize_invalid_link_2 :: proc(t: ^testing.T) {
	input_string := "Here is an [invalid link?]!"
	tokens := tokenize(input_string)

	expected_token: Token = {
		line    = 1,
		type    = TokenType.TEXT,
		content = "Here is an [invalid link?]!",
	}

	testing.expect(t, expected_token == tokens[0])
}

compare_token_slices :: proc(first: []Token, second: []Token) -> (are_equal: bool) {
	if len(first) != len(second) {
		fmt.eprintfln(
			"ERROR: Slice lengths are not equal. first len: %v; second len: %v",
			len(first),
			len(second),
		)
	}

	for token, i in first {
		if second[i] != token {
			return false
		}
	}

	return true
}
