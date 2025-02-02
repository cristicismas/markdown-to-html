package tokenizer

import "core:fmt"
import "core:strings"
import "core:unicode/utf8"

TOKEN_RUNES: []rune = {'-', '>', '[', '#', '*', '_', '`', '!', '\n', '\r', '\\', utf8.RUNE_ERROR}

TokenType :: enum {
	TEXT,
	PARAGRAPH,
	HASH_1,
	HASH_2,
	HASH_3,
	HASH_4,
	HASH_5,
	HASH_6,
	BOLD,
	ITALIC,
	BOLD_ITALIC,
	UNORDERED_LI,
	ORDERED_LI,
	NEW_LINE,
	QUOTE,
	CODE,
	CODE_BLOCK,
	LINK,
	IMAGE,
	EOF,
	ERROR,
}

Token :: struct {
	type:    TokenType,
	line:    int,
	content: string,
	link:    string,
}

Scanner :: struct {
	source:     string,
	// number of runes in source (not bytes)
	source_len: int,
	tokens:     [dynamic]Token,
	// Start index of current scan
	start:      int,
	// Current index of the current scan
	current:    int,
	// Current line of the scan
	line:       int,
}

tokenize :: proc(markdown: string) -> []Token {
	scanner := Scanner {
		source     = markdown,
		source_len = strings.rune_count(markdown),
		tokens     = [dynamic]Token{},
		start      = 0,
		current    = 0,
		line       = 1,
	}

	for !is_at_end(&scanner) {
		scanner.start = scanner.current
		scan_next_token(&scanner)
	}

	add_token(&scanner, TokenType.EOF)

	return scanner.tokens[:]
}

advance :: proc(scanner: ^Scanner) -> rune {
	current_rune := utf8.rune_at_pos(scanner.source, scanner.current)
	scanner.current += 1

	return current_rune
}

add_token :: proc {
	add_token_type,
	add_token_text,
	add_token_link,
	add_token_with_content,
}

add_token_type :: proc(scanner: ^Scanner, token_type: TokenType) {
	token := Token {
		type = token_type,
		line = scanner.line,
	}
	append(&scanner.tokens, token)
}

add_token_text :: proc(scanner: ^Scanner, text: string) {
	new_text_token := Token {
		content = text,
		type    = TokenType.TEXT,
		line    = scanner.line,
	}

	is_paragraph := check_is_paragraph(scanner)

	if is_paragraph {
		p_token := Token {
			type = TokenType.PARAGRAPH,
			line = scanner.line,
		}
		append(&scanner.tokens, p_token)
	}

	// if the previous token was already text, consolidate them.
	if len(scanner.tokens) > 0 {
		previous_token := &scanner.tokens[len(scanner.tokens) - 1]

		if previous_token.type == TokenType.TEXT {
			previous_token.content = strings.concatenate({previous_token.content, text})
		} else {
			append(&scanner.tokens, new_text_token)
		}
	} else {
		append(&scanner.tokens, new_text_token)
	}
}

add_token_with_content :: proc(scanner: ^Scanner, token_type: TokenType, text: string) {
	token := Token {
		content = text,
		type    = token_type,
		line    = scanner.line,
	}

	append(&scanner.tokens, token)
}

add_token_link :: proc(
	scanner: ^Scanner,
	text: string,
	link: string,
	token_type: TokenType = TokenType.LINK,
) {
	assert(token_type == TokenType.LINK || token_type == TokenType.IMAGE)

	token := Token {
		content = text,
		link    = link,
		type    = token_type,
		line    = scanner.line,
	}

	append(&scanner.tokens, token)
}

scan_next_token :: proc(scanner: ^Scanner) {
	// Free temporarily allocated strings each new scan
	defer free_all(context.temp_allocator)

	current_rune := advance(scanner)

	tt :: TokenType

	switch current_rune {
	// Single character
	case '\\':
		next := peek_single(scanner, scanner.current)

		if next != utf8.RUNE_ERROR && next != '\n' && next != '\r' {
			add_token(scanner, utf8.runes_to_string({next}))
		}
		scanner.current += 1
	case '\n':
		add_token(scanner, tt.NEW_LINE)
		scanner.line += 1
	case '\r':
		next := peek_single(scanner, scanner.current)
		if next != '\n' {
			add_token(scanner, "\r")
		} else {
			break
		}
	case '-':
		next := peek_single(scanner, scanner.current)
		if next == ' ' {
			add_token(scanner, tt.UNORDERED_LI)
			scanner.current += 1
		} else {
			add_token(scanner, "-")
		}
	case '0' ..= '9':
		if len(scanner.tokens) > 0 && scanner.tokens[len(scanner.tokens) - 1].type == tt.NEW_LINE {
			until_next_whitespace, ok := peek_until_next_specific_token(
				scanner,
				' ',
				scanner.current,
			)

			last_elem :=
				len(until_next_whitespace) > 0 ? utf8.rune_at_pos(until_next_whitespace, len(until_next_whitespace) - 1) : utf8.RUNE_ERROR

			until_dot :=
				len(until_next_whitespace) > 0 ? until_next_whitespace[:len(until_next_whitespace) - 1] : ""

			is_sequence_numeric := len(until_next_whitespace) == 0 || is_numeric(until_dot)

			if !ok || !is_sequence_numeric || last_elem != '.' {
				add_token(scanner, until_next_whitespace)
				scanner.current += strings.rune_count(until_next_whitespace) - 1
				break
			}

			add_token(scanner, tt.ORDERED_LI)
			scanner.current += strings.rune_count(until_next_whitespace)
		} else {
			add_token(scanner, utf8.runes_to_string({current_rune}))
		}
	case '>':
		prev_char := peek_single(scanner, scanner.current - 2)
		is_at_file_beginning := prev_char == utf8.RUNE_ERROR

		if prev_char == '\n' || is_at_file_beginning {
			add_token(scanner, tt.QUOTE)
		} else {
			add_token(scanner, ">")
		}
	// More complex cases
	case '#':
		matched_token, token_length, ok := scan_same_kind_tokens(
			scanner,
			6,
			"#",
			{tt.HASH_1, tt.HASH_2, tt.HASH_3, tt.HASH_4, tt.HASH_5, tt.HASH_6},
		)

		if ok {
			add_token(scanner, matched_token)
			scanner.current += token_length
		}
	case '*':
		matched_token, token_length, ok := scan_same_kind_tokens(
			scanner,
			3,
			"*",
			{tt.ITALIC, tt.BOLD, tt.BOLD_ITALIC},
		)

		if ok {
			add_token(scanner, matched_token)
			scanner.current += token_length
		}
	case '_':
		matched_token, token_length, ok := scan_same_kind_tokens(
			scanner,
			3,
			"_",
			{tt.ITALIC, tt.BOLD, tt.BOLD_ITALIC},
		)

		if ok {
			add_token(scanner, matched_token)
			scanner.current += token_length
		}
	case '`':
		if peek_multiple(scanner, 2) == "``" {
			scanner.current += 2

			text_until_next_code_block, ok := peek_until_next_sequence(
				scanner,
				"```",
				scanner.current,
			)
			length_to_add := utf8.rune_count(text_until_next_code_block) + 3

			// remove the text on the same line as the code block beginning
			start_index := 0
			for r in text_until_next_code_block {
				start_index += 1
				if r == '\n' {
					break
				}
			}

			text_until_next_code_block = slice_by_rune(
				text_until_next_code_block,
				start_index,
				utf8.rune_count(text_until_next_code_block),
			)

			// If we can't find the next CODE_BLOCK sequence in the source file,
			// then just add this token as a string
			if !ok {
				add_token(scanner, "```")
				return
			}

			scanner.current += length_to_add

			add_token(scanner, tt.CODE_BLOCK, text_until_next_code_block)
		} else {
			add_token(scanner, tt.CODE)
		}
	case '[':
		try_scan_link(scanner, TokenType.LINK)
	case '!':
		next := peek_single(scanner, scanner.current)

		if next != '[' {
			add_token(scanner, "!")
		} else {
			scanner.current += 1
			try_scan_link(scanner, TokenType.IMAGE)
		}
	// Error
	case utf8.RUNE_ERROR:
		fmt.eprintfln(
			"ERROR: Got a rune error when scanning at: start: %v, current: %v, line: %v",
			scanner.start,
			scanner.current,
			scanner.line,
		)
	// Text
	case:
		text := peek_until_next_token(scanner, scanner.current)
		text_len := strings.rune_count(text)

		scanner.current += text_len - 1
		add_token(scanner, text)
	}
}

is_at_end :: proc {
	is_at_end_scanner,
	is_at_end_index,
}

is_at_end_scanner :: proc(scanner: ^Scanner) -> bool {
	at_end := scanner.current >= scanner.source_len

	return at_end
}

is_at_end_index :: proc(scanner: ^Scanner, index: int) -> bool {
	at_end := index >= scanner.source_len

	return at_end
}
