package tokenizer

import "core:fmt"
import "core:testing"

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

// TODO: add tests for code, code_block
@(test)
tokenize_quote_simple :: proc(t: ^testing.T) {
	input_string := "> Simple quote example"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.QUOTE},
		{line = 1, type = TokenType.TEXT, content = " Simple quote example"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_quote_after_newline :: proc(t: ^testing.T) {
	input_string := "\n> Simple quote example"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.NEW_LINE},
		{line = 2, type = TokenType.QUOTE},
		{line = 2, type = TokenType.TEXT, content = " Simple quote example"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_code_simple :: proc(t: ^testing.T) {
	input_string := "Hi, here is a simple `code`"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.TEXT, content = "Hi, here is a simple "},
		{line = 1, type = TokenType.CODE},
		{line = 1, type = TokenType.TEXT, content = "code"},
		{line = 1, type = TokenType.CODE},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_code_block :: proc(t: ^testing.T) {
	input_string := "Hi, here is a ```code block\nanother code block line\nand another```"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.TEXT, content = "Hi, here is a "},
		{
			line = 1,
			type = TokenType.CODE_BLOCK,
			content = "code block\nanother code block line\nand another",
		},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_italic :: proc(t: ^testing.T) {
	input_string := "Here is a *bold* text and another _bold_ text"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.TEXT, content = "Here is a "},
		{line = 1, type = TokenType.ITALIC},
		{line = 1, type = TokenType.TEXT, content = "bold"},
		{line = 1, type = TokenType.ITALIC},
		{line = 1, type = TokenType.TEXT, content = " text and another "},
		{line = 1, type = TokenType.ITALIC},
		{line = 1, type = TokenType.TEXT, content = "bold"},
		{line = 1, type = TokenType.ITALIC},
		{line = 1, type = TokenType.TEXT, content = " text"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_bold :: proc(t: ^testing.T) {
	input_string := "Here is a **bold** text and another __bold__ text"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.TEXT, content = "Here is a "},
		{line = 1, type = TokenType.BOLD},
		{line = 1, type = TokenType.TEXT, content = "bold"},
		{line = 1, type = TokenType.BOLD},
		{line = 1, type = TokenType.TEXT, content = " text and another "},
		{line = 1, type = TokenType.BOLD},
		{line = 1, type = TokenType.TEXT, content = "bold"},
		{line = 1, type = TokenType.BOLD},
		{line = 1, type = TokenType.TEXT, content = " text"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_bold_italic :: proc(t: ^testing.T) {
	input_string := "Here is a ***bold*** text and another ___bold___ text"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.TEXT, content = "Here is a "},
		{line = 1, type = TokenType.BOLD_ITALIC},
		{line = 1, type = TokenType.TEXT, content = "bold"},
		{line = 1, type = TokenType.BOLD_ITALIC},
		{line = 1, type = TokenType.TEXT, content = " text and another "},
		{line = 1, type = TokenType.BOLD_ITALIC},
		{line = 1, type = TokenType.TEXT, content = "bold"},
		{line = 1, type = TokenType.BOLD_ITALIC},
		{line = 1, type = TokenType.TEXT, content = " text"},
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

@(test)
tokenize_invalid_link_3 :: proc(t: ^testing.T) {
	input_string := "Here is a [!"
	tokens := tokenize(input_string)

	expected_token: Token = {
		line    = 1,
		type    = TokenType.TEXT,
		content = "Here is a [!",
	}

	testing.expect(t, expected_token == tokens[0])
}

@(test)
tokenize_image_simple :: proc(t: ^testing.T) {
	input_string := "Here is an ![image alt](https://placehold.co/600x400)!"
	tokens := tokenize(input_string)

	expected_tokens: [3]Token = {
		{line = 1, type = TokenType.TEXT, content = "Here is an "},
		{
			line = 1,
			type = TokenType.IMAGE,
			content = "image alt",
			link = "https://placehold.co/600x400",
		},
		{line = 1, type = TokenType.TEXT, content = "!"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_image_with_figcap :: proc(t: ^testing.T) {
	input_string := "Here is an ![image alt](https://placehold.co/600x400 \"Figure caption\")!"
	tokens := tokenize(input_string)

	expected_tokens: [3]Token = {
		{line = 1, type = TokenType.TEXT, content = "Here is an "},
		{
			line = 1,
			type = TokenType.IMAGE,
			content = "image alt",
			link = "https://placehold.co/600x400 \"Figure caption\"",
		},
		{line = 1, type = TokenType.TEXT, content = "!"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))

}

@(test)
tokenize_image_empty :: proc(t: ^testing.T) {
	input_string := "Here is an ![]()!"
	tokens := tokenize(input_string)

	expected_tokens: [3]Token = {
		{line = 1, type = TokenType.TEXT, content = "Here is an "},
		{line = 1, type = TokenType.IMAGE, content = "", link = ""},
		{line = 1, type = TokenType.TEXT, content = "!"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))

}

@(test)
tokenize_image_invalid :: proc(t: ^testing.T) {
	input_string := "Here is an ![](!"
	tokens := tokenize(input_string)

	expected_tokens: [1]Token = {{line = 1, type = TokenType.TEXT, content = "Here is an ![](!"}}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_image_invalid_2 :: proc(t: ^testing.T) {
	input_string := "Here is an ![]!"
	tokens := tokenize(input_string)

	expected_tokens: [1]Token = {{line = 1, type = TokenType.TEXT, content = "Here is an ![]!"}}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_image_invalid_3 :: proc(t: ^testing.T) {
	input_string := "Here is an ![!"
	tokens := tokenize(input_string)

	expected_tokens: [1]Token = {{line = 1, type = TokenType.TEXT, content = "Here is an ![!"}}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_new_line :: proc(t: ^testing.T) {
	input_string := "Here is a \n new line"
	tokens := tokenize(input_string)

	expected_tokens: [3]Token = {
		{line = 1, type = TokenType.TEXT, content = "Here is a "},
		{line = 1, type = TokenType.NEW_LINE},
		{line = 2, type = TokenType.TEXT, content = " new line"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_new_line_and_invalid_image :: proc(t: ^testing.T) {
	input_string := "Here is a !\n[](! new line"
	tokens := tokenize(input_string)

	expected_tokens: [3]Token = {
		{line = 1, type = TokenType.TEXT, content = "Here is a !"},
		{line = 1, type = TokenType.NEW_LINE},
		{line = 2, type = TokenType.TEXT, content = "[](! new line"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_carriage_return_new_line :: proc(t: ^testing.T) {
	input_string := "Here is a \r\n new line"
	tokens := tokenize(input_string)

	expected_tokens: [3]Token = {
		{line = 1, type = TokenType.TEXT, content = "Here is a "},
		{line = 1, type = TokenType.NEW_LINE},
		{line = 2, type = TokenType.TEXT, content = " new line"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_carriage_return_invalid :: proc(t: ^testing.T) {
	input_string := "Here is an \r invalid cr"
	tokens := tokenize(input_string)

	expected_tokens: [1]Token = {
		{line = 1, type = TokenType.TEXT, content = "Here is an \r invalid cr"},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
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
