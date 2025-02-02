package tokenizer

import "core:fmt"
import "core:testing"

@(test)
tokenize_h1_test :: proc(t: ^testing.T) {
	input_string := "# h1 tokenize test"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.HASH_1},
		{line = 1, type = TokenType.TEXT, content = " h1 tokenize test"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_paragraph_beginning :: proc(t: ^testing.T) {
	input_string := "This is a paragraph at the beginning of the string"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{
			line = 1,
			type = TokenType.TEXT,
			content = "This is a paragraph at the beginning of the string",
		},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_paragraph_beginning_with_new_line :: proc(t: ^testing.T) {
	input_string := "\nThis is a paragraph at the beginning of the string"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.NEW_LINE},
		{line = 2, type = TokenType.PARAGRAPH},
		{
			line = 2,
			type = TokenType.TEXT,
			content = "This is a paragraph at the beginning of the string",
		},
		{line = 2, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_paragraph_complex :: proc(t: ^testing.T) {
	input_string := "\nThis is a \n\nparagraph at the \n\n\nbeginning of \nthe string"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.NEW_LINE},
		{line = 2, type = TokenType.PARAGRAPH},
		{line = 2, type = TokenType.TEXT, content = "This is a "},
		{line = 2, type = TokenType.NEW_LINE},
		{line = 3, type = TokenType.NEW_LINE},
		{line = 4, type = TokenType.PARAGRAPH},
		{line = 4, type = TokenType.TEXT, content = "paragraph at the "},
		{line = 4, type = TokenType.NEW_LINE},
		{line = 5, type = TokenType.NEW_LINE},
		{line = 6, type = TokenType.NEW_LINE},
		{line = 7, type = TokenType.PARAGRAPH},
		{line = 7, type = TokenType.TEXT, content = "beginning of "},
		{line = 7, type = TokenType.NEW_LINE},
		{line = 8, type = TokenType.TEXT, content = "the string"},
		{line = 8, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_quote_simple :: proc(t: ^testing.T) {
	input_string := "> Simple quote example"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.QUOTE},
		{line = 1, type = TokenType.TEXT, content = " Simple quote example"},
		{line = 1, type = TokenType.EOF},
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
		{line = 2, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_code_simple :: proc(t: ^testing.T) {
	input_string := "Hi, here is a simple `code`"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Hi, here is a simple "},
		{line = 1, type = TokenType.CODE},
		{line = 1, type = TokenType.TEXT, content = "code"},
		{line = 1, type = TokenType.CODE},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_code_block :: proc(t: ^testing.T) {
	input_string := "Hi, here is a ```code block\nanother code block line\nand another```"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Hi, here is a "},
		{
			line = 1,
			type = TokenType.CODE_BLOCK,
			content = "code block\nanother code block line\nand another",
		},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_italic :: proc(t: ^testing.T) {
	input_string := "Here is a *bold* text and another _bold_ text"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is a "},
		{line = 1, type = TokenType.ITALIC},
		{line = 1, type = TokenType.TEXT, content = "bold"},
		{line = 1, type = TokenType.ITALIC},
		{line = 1, type = TokenType.TEXT, content = " text and another "},
		{line = 1, type = TokenType.ITALIC},
		{line = 1, type = TokenType.TEXT, content = "bold"},
		{line = 1, type = TokenType.ITALIC},
		{line = 1, type = TokenType.TEXT, content = " text"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_bold :: proc(t: ^testing.T) {
	input_string := "Here is a **bold** text and another __bold__ text"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is a "},
		{line = 1, type = TokenType.BOLD},
		{line = 1, type = TokenType.TEXT, content = "bold"},
		{line = 1, type = TokenType.BOLD},
		{line = 1, type = TokenType.TEXT, content = " text and another "},
		{line = 1, type = TokenType.BOLD},
		{line = 1, type = TokenType.TEXT, content = "bold"},
		{line = 1, type = TokenType.BOLD},
		{line = 1, type = TokenType.TEXT, content = " text"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_bold_italic :: proc(t: ^testing.T) {
	input_string := "Here is a ***bold*** text and another ___bold___ text"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is a "},
		{line = 1, type = TokenType.BOLD_ITALIC},
		{line = 1, type = TokenType.TEXT, content = "bold"},
		{line = 1, type = TokenType.BOLD_ITALIC},
		{line = 1, type = TokenType.TEXT, content = " text and another "},
		{line = 1, type = TokenType.BOLD_ITALIC},
		{line = 1, type = TokenType.TEXT, content = "bold"},
		{line = 1, type = TokenType.BOLD_ITALIC},
		{line = 1, type = TokenType.TEXT, content = " text"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_link_simple_test :: proc(t: ^testing.T) {
	input_string := "Here is a [link](https://www.google.com)!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is a "},
		{line = 1, type = TokenType.LINK, content = "link", link = "https://www.google.com"},
		{line = 1, type = TokenType.TEXT, content = "!"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_link_empty_test :: proc(t: ^testing.T) {
	input_string := "Here is an empty link []()!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is an empty link "},
		{line = 1, type = TokenType.LINK, content = "", link = ""},
		{line = 1, type = TokenType.TEXT, content = "!"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_link_invalid :: proc(t: ^testing.T) {
	input_string := "Here is a [](!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is a [](!"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_link_invalid_2 :: proc(t: ^testing.T) {
	input_string := "Here is an [invalid link?]!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is an [invalid link?]!"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_link_invalid_3 :: proc(t: ^testing.T) {
	input_string := "Here is a [!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is a [!"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))

}

@(test)
tokenize_image_simple :: proc(t: ^testing.T) {
	input_string := "Here is an ![image alt](https://placehold.co/600x400)!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is an "},
		{
			line = 1,
			type = TokenType.IMAGE,
			content = "image alt",
			link = "https://placehold.co/600x400",
		},
		{line = 1, type = TokenType.TEXT, content = "!"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_image_with_figcap :: proc(t: ^testing.T) {
	input_string := "Here is an ![image alt](https://placehold.co/600x400 \"Figure caption\")!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is an "},
		{
			line = 1,
			type = TokenType.IMAGE,
			content = "image alt",
			link = "https://placehold.co/600x400 \"Figure caption\"",
		},
		{line = 1, type = TokenType.TEXT, content = "!"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))

}

@(test)
tokenize_image_empty :: proc(t: ^testing.T) {
	input_string := "Here is an ![]()!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is an "},
		{line = 1, type = TokenType.IMAGE, content = "", link = ""},
		{line = 1, type = TokenType.TEXT, content = "!"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))

}

@(test)
tokenize_image_invalid :: proc(t: ^testing.T) {
	input_string := "Here is an ![](!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is an ![](!"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_image_invalid_2 :: proc(t: ^testing.T) {
	input_string := "Here is an ![]!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is an ![]!"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_image_invalid_3 :: proc(t: ^testing.T) {
	input_string := "Here is an ![!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is an ![!"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_new_line :: proc(t: ^testing.T) {
	input_string := "Here is a \n new line"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is a "},
		{line = 1, type = TokenType.NEW_LINE},
		{line = 2, type = TokenType.TEXT, content = " new line"},
		{line = 2, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_new_line_and_invalid_image :: proc(t: ^testing.T) {
	input_string := "Here is a !\n[](! new line"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is a !"},
		{line = 1, type = TokenType.NEW_LINE},
		{line = 2, type = TokenType.TEXT, content = "[](! new line"},
		{line = 2, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_carriage_return_new_line :: proc(t: ^testing.T) {
	input_string := "Here is a \r\n new line"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is a "},
		{line = 1, type = TokenType.NEW_LINE},
		{line = 2, type = TokenType.TEXT, content = " new line"},
		{line = 2, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_carriage_return_invalid :: proc(t: ^testing.T) {
	input_string := "Here is an \r invalid cr"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is an \r invalid cr"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_escape_characters :: proc(t: ^testing.T) {
	input_string := "Here is an escaped \\# H1 tag and an escaped \\\\ backwards slash."
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{
			line = 1,
			type = TokenType.TEXT,
			content = "Here is an escaped # H1 tag and an escaped \\ backwards slash.",
		},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_unordered_list :: proc(t: ^testing.T) {
	input_string := "Here is a list: \n- first\n- second\n- third with __bold__\nList has ended!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is a list: "},
		{line = 1, type = TokenType.NEW_LINE},
		{line = 2, type = TokenType.UNORDERED_LI},
		{line = 2, type = TokenType.TEXT, content = "first"},
		{line = 2, type = TokenType.NEW_LINE},
		{line = 3, type = TokenType.UNORDERED_LI},
		{line = 3, type = TokenType.TEXT, content = "second"},
		{line = 3, type = TokenType.NEW_LINE},
		{line = 4, type = TokenType.UNORDERED_LI},
		{line = 4, type = TokenType.TEXT, content = "third with "},
		{line = 4, type = TokenType.BOLD},
		{line = 4, type = TokenType.TEXT, content = "bold"},
		{line = 4, type = TokenType.BOLD},
		{line = 4, type = TokenType.NEW_LINE},
		{line = 5, type = TokenType.TEXT, content = "List has ended!"},
		{line = 5, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_ordered_list :: proc(t: ^testing.T) {
	input_string := "Here is a list: \n1. first\n2. second\n3. third with __bold__\nList has ended!"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "Here is a list: "},
		{line = 1, type = TokenType.NEW_LINE},
		{line = 2, type = TokenType.ORDERED_LI},
		{line = 2, type = TokenType.TEXT, content = "first"},
		{line = 2, type = TokenType.NEW_LINE},
		{line = 3, type = TokenType.ORDERED_LI},
		{line = 3, type = TokenType.TEXT, content = "second"},
		{line = 3, type = TokenType.NEW_LINE},
		{line = 4, type = TokenType.ORDERED_LI},
		{line = 4, type = TokenType.TEXT, content = "third with "},
		{line = 4, type = TokenType.BOLD},
		{line = 4, type = TokenType.TEXT, content = "bold"},
		{line = 4, type = TokenType.BOLD},
		{line = 4, type = TokenType.NEW_LINE},
		{line = 5, type = TokenType.TEXT, content = "List has ended!"},
		{line = 5, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_utf8_string_simple :: proc(t: ^testing.T) {
	input_string := "‰ŒĐ"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "‰ŒĐ"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}

@(test)
tokenize_utf8_emojis :: proc(t: ^testing.T) {
	input_string := "😀🙂🫥"
	tokens := tokenize(input_string)

	expected_tokens := [?]Token {
		{line = 1, type = TokenType.PARAGRAPH},
		{line = 1, type = TokenType.TEXT, content = "😀🙂🫥"},
		{line = 1, type = TokenType.EOF},
	}

	testing.expect(t, compare_token_slices(expected_tokens[:], tokens))
}
