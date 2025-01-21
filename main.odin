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
	markdown_to_html("# This is an h1")
}

markdown_to_html :: proc(markdown: string) -> (html: string) {
	tokens := tokenize(markdown)

	return ""
}


TokenType :: enum {
	TEXT,
	HASH,
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

	for token in scanner.tokens {
		fmt.println("")
		print_token(token)
	}

	return scanner.tokens[:]
}

advance :: proc(scanner: ^Scanner) -> rune {
	current_rune := utf8.rune_at_pos(scanner.source, cast(int)scanner.current)
	scanner.current += 1

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
	case '!':
		add_token(scanner, tt.BANG)
	case '[':
		add_token(scanner, tt.LEFT_BRACKET)
	case ']':
		add_token(scanner, tt.RIGHT_BRACKET)
	case '(':
		add_token(scanner, tt.LEFT_PARENTHESIS)
	case ')':
		add_token(scanner, tt.RIGHT_PARENTHESIS)

	// TODO: peek ahead for multiple-character tokens
	// - try to use parapoly to check the next 'n' elements
	// - peek ahead with regex for more complicated cases (like images and links)
	case '#':
	case '*':
	case '_':
	case '`':
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
