#+private file
package main

import sa "core:container/small_array"
import "core:fmt"
import "core:reflect"
import "core:strings"
import "core:unicode/utf8"

TokenType :: enum {
	TEXT,
	HASH_1,
	HASH_2,
	HASH_3,
	HASH_4,
	HASH_5,
	HASH_6,
	UNDERSCORE,
	DASH,
	STAR,
	NEW_LINE,
	QUOTE,
	BANG,
	BACKTICK,
	LEFT_BRACKET,
	RIGHT_BRACKET,
	LEFT_PARENTHESIS,
	RIGHT_PARENTHESIS,
}

Token :: struct {
	type:    TokenType,
	line:    u32,
	content: string,
}

Scanner :: struct {
	source:  string,
	tokens:  [dynamic]Token,
	// Start index of current scan
	start:   u32,
	// Current index of the current scan
	current: u32,
	// Current line of the scan
	line:    u32,
}

@(private = "package")
tokenize :: proc(markdown: string) -> []Token {
	scanner := Scanner {
		source  = markdown,
		tokens  = [dynamic]Token{},
		start   = 0,
		current = 0,
		line    = 1,
	}

	for !is_at_end(&scanner) {
		scanner.start = scanner.current
		scan_next_token(&scanner)
	}

	print_tokens(scanner.tokens[:])

	return scanner.tokens[:]
}

advance :: proc(scanner: ^Scanner) -> rune {
	current_rune := utf8.rune_at_pos(scanner.source, cast(int)scanner.current)
	scanner.current += 1

	return current_rune
}

// Peeks multiple elements ahead of the scanner's current position
peek_multiple :: proc(scanner: ^Scanner, count: int) -> string {
	index := cast(int)scanner.current
	loops := 0

	runes := make([dynamic]rune, 0, count)
	defer delete(runes)

	for loops < count {
		start_index := cast(int)scanner.current + loops
		new_rune := peek_single(scanner, start_index)
		append(&runes, new_rune)

		loops += 1
	}

	string := utf8.runes_to_string(runes[:])
	return string
}

peek_single :: proc(scanner: ^Scanner, index: int) -> rune {
	current_rune := utf8.rune_at_pos(scanner.source, index)
	return current_rune
}

add_token :: proc {
	add_token_type,
	add_token_literal,
}

add_token_type :: proc(scanner: ^Scanner, token_type: TokenType) {
	token := Token {
		type = token_type,
		line = scanner.line,
	}
	append(&scanner.tokens, token)
}

add_token_literal :: proc(scanner: ^Scanner, start_index: u32, current_index: u32) {
	token := Token {
		content = scanner.source[scanner.start:scanner.current],
		line    = scanner.line,
	}
	append(&scanner.tokens, token)
}

scan_next_token :: proc(scanner: ^Scanner) {
	current_rune := advance(scanner)

	tt :: TokenType

	switch current_rune {
	// Single character
	case '-':
		add_token(scanner, tt.DASH)
	case '\n':
		add_token(scanner, tt.NEW_LINE)
	case '>':
		add_token(scanner, tt.QUOTE)
	case '[':
		add_token(scanner, tt.LEFT_BRACKET)
	case ']':
		add_token(scanner, tt.RIGHT_BRACKET)
	case '(':
		add_token(scanner, tt.LEFT_PARENTHESIS)
	case ')':
		add_token(scanner, tt.RIGHT_PARENTHESIS)

	// TODO: peek ahead for multiple-character tokens
	// - try to check the next 'n' elements
	// - peek ahead with regex for more complicated cases (like images and links)
	case '#':
		switch {
		case peek_multiple(scanner, 5) == "#####":
			add_token(scanner, tt.HASH_6)
			scanner.current += 5
		case peek_multiple(scanner, 4) == "####":
			add_token(scanner, tt.HASH_5)
			scanner.current += 4
		case peek_multiple(scanner, 3) == "###":
			add_token(scanner, tt.HASH_4)
			scanner.current += 3
		case peek_multiple(scanner, 2) == "##":
			add_token(scanner, tt.HASH_3)
			scanner.current += 2
		case peek_multiple(scanner, 1) == "#":
			add_token(scanner, tt.HASH_2)
			scanner.current += 1
		case:
			add_token(scanner, tt.HASH_1)
		}
	case '*':
	case '_':
	case '`':
	case '!':
	// Ignore whitespace, tabs, returns
	case ' ':
	case '\t':
	case '\r':
	// Error
	case utf8.RUNE_ERROR:
		fmt.eprintfln(
			"Got a rune error when scanning at: start: %v, current: %v, line: %v",
			scanner.start,
			scanner.current,
			scanner.line,
		)
	}
}

is_at_end :: proc(scanner: ^Scanner) -> bool {
	runes_count := strings.rune_count(scanner.source)
	at_end := cast(int)scanner.current >= runes_count

	return at_end
}

print_token :: proc(token: Token) {
	if name, ok := reflect.enum_name_from_value(token.type); ok {
		fmt.print(name)
	}
}

print_tokens :: proc(tokens: []Token) {
	for token, i in tokens {
		print_token(token)

		if i < len(tokens) - 1 {
			fmt.print(", ")
		} else {
			fmt.print("\n")
		}
	}
}
