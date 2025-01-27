package tokenizer

import sa "core:container/small_array"
import "core:fmt"
import "core:reflect"
import "core:slice"
import "core:strings"
import "core:unicode/utf8"

TOKEN_RUNES: []rune = {'-', '>', '[', '#', '*', '_', '`', '!', '\n', '\r', utf8.RUNE_ERROR}

TokenType :: enum {
	TEXT,
	HASH_1,
	HASH_2,
	HASH_3,
	HASH_4,
	HASH_5,
	HASH_6,
	BOLD,
	ITALIC,
	BOLD_ITALIC,
	DASH,
	NEW_LINE,
	QUOTE,
	CODE,
	CODE_BLOCK,
	LINK,
	IMAGE,
	ERROR,
}

Token :: struct {
	type:    TokenType,
	line:    u32,
	content: string,
	link:    string,
}

Scanner :: struct {
	source:     string,
	// number of runes in source (not bytes)
	source_len: int,
	tokens:     [dynamic]Token,
	// Start index of current scan
	start:      u32,
	// Current index of the current scan
	current:    u32,
	// Current line of the scan
	line:       u32,
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

	string := utf8.runes_to_string(runes[:], context.temp_allocator)
	return string
}

peek_single :: proc(scanner: ^Scanner, index: int) -> rune {
	current_rune := utf8.rune_at_pos(scanner.source, index)
	return current_rune
}

add_token :: proc {
	add_token_type,
	add_token_text,
	add_token_link,
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
	case '\n':
		add_token(scanner, tt.NEW_LINE)
		scanner.line += 1
	case '\r':
		next := peek_single(scanner, cast(int)scanner.current)
		if next != '\n' {
			add_token(scanner, "\r")
		} else {
			break
		}
	case '-':
		add_token(scanner, tt.DASH)
	case '>':
		add_token(scanner, tt.QUOTE)
	// More complex cases
	case '#':
		matched_token, token_length, ok := match_same_kind_tokens(
			scanner,
			6,
			"#",
			{tt.HASH_1, tt.HASH_2, tt.HASH_3, tt.HASH_4, tt.HASH_5, tt.HASH_6},
		)

		if ok {
			add_token(scanner, matched_token)
			scanner.current += cast(u32)token_length
		}
	case '*':
		matched_token, token_length, ok := match_same_kind_tokens(
			scanner,
			3,
			"*",
			{tt.BOLD, tt.ITALIC, tt.BOLD_ITALIC},
		)

		if ok {
			add_token(scanner, matched_token)
			scanner.current += cast(u32)token_length
		}
	case '_':
		matched_token, token_length, ok := match_same_kind_tokens(
			scanner,
			3,
			"_",
			{tt.BOLD, tt.ITALIC, tt.BOLD_ITALIC},
		)

		if ok {
			add_token(scanner, matched_token)
			scanner.current += cast(u32)token_length
		}
	case '`':
		if peek_multiple(scanner, 2) == "``" {
			add_token(scanner, tt.CODE_BLOCK)
			scanner.current += 2
		} else {
			add_token(scanner, tt.CODE)
		}
	case '[':
		try_scan_link(scanner, TokenType.LINK)
	case '!':
		next := peek_single(scanner, cast(int)scanner.current)

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

		scanner.current += cast(u32)text_len - 1
		add_token(scanner, text)
	}
}

try_scan_link :: proc(scanner: ^Scanner, link_type: TokenType) {
	assert(link_type == TokenType.LINK || link_type == TokenType.IMAGE)

	look_ahead, ok := peek_until_next_specific_token(scanner, ']', scanner.current)

	if !ok {
		text := peek_until_next_token(scanner, scanner.current)
		text_len := strings.rune_count(text)

		if link_type == TokenType.IMAGE {
			text = strings.concatenate({"!", text})
		}

		scanner.current += cast(u32)text_len - 1

		add_token(scanner, text)
		return
	}

	link_text := look_ahead[1:]

	new_lookup_offset := cast(int)scanner.current + strings.rune_count(look_ahead)

	// Look for the next character
	next_rune := peek_single(scanner, new_lookup_offset)

	// If we can't find the next paranthesis, just add the string as a TEXT token
	if next_rune != '(' {
		text := strings.concatenate({"[", link_text, "]"})
		if link_type == TokenType.IMAGE {
			text = strings.concatenate({"!", text})
		}
		add_token(scanner, text)
		scanner.current = cast(u32)new_lookup_offset
		return
	}

	new_lookup_offset += 1

	href_look_ahead, ok_2 := peek_until_next_specific_token(
		scanner,
		')',
		cast(u32)new_lookup_offset,
	)

	if !ok_2 {
		text := strings.concatenate({"[", link_text, "]", "("})
		text_len := strings.rune_count(text)

		if link_type == TokenType.IMAGE {
			text = strings.concatenate({"!", text})
		}

		scanner.current += cast(u32)text_len - 1
		add_token(scanner, text)
		return
	}

	link_href := href_look_ahead[1:]

	add_token(scanner, link_text, link_href, link_type)

	link_len := strings.rune_count(
		strings.concatenate({"[", link_text, "]", "(", link_href, ")"}, context.temp_allocator),
	)
	scanner.current += cast(u32)link_len - 1

}

peek_until_next_token :: proc(scanner: ^Scanner, start_index: u32) -> string {
	search_index := start_index

	for !is_at_end(scanner, cast(int)search_index - 1) {
		current_rune := utf8.rune_at_pos(scanner.source, cast(int)search_index)

		if slice.contains(TOKEN_RUNES, current_rune) {
			if search_index < scanner.current {
				fmt.eprintfln(
					"ERROR: Unable to index the correct slice for the given parameters: search_index: %v, current_rune: %v",
					search_index,
					current_rune,
				)
				return ""
			}

			return scanner.source[start_index - 1:search_index]
		}

		search_index += 1
	}

	return scanner.source[scanner.current:search_index - 1]
}

peek_until_next_specific_token :: proc(
	scanner: ^Scanner,
	token: rune,
	start_index: u32,
) -> (
	result: string,
	ok: bool,
) {
	search_index := start_index

	for !is_at_end(scanner, cast(int)search_index - 1) {
		current_rune := utf8.rune_at_pos(scanner.source, cast(int)search_index)

		if current_rune == token {
			if search_index < scanner.current {
				fmt.eprintfln(
					"ERROR: Unable to index the correct slice for the given parameters: search_index: %v, current_rune: %v",
					search_index,
					current_rune,
				)
				return "", false
			}

			return scanner.source[start_index - 1:search_index], true
		}

		search_index += 1
	}

	return "", false
}

/*
	Searches the next 'max_count' elements, starting from the scanner's current position, and compares
	each permutation of 'compare_str' up to max_count, to see if we get any matches.

	This is useful when searching for all permutations of headings for example:
		#
		##
		###
		####
		#####
		######
	
	Important: token_types need to be passed in ascending order, so for the heading example, we
	would have: HASH_1, HASH_2, ..., HASH_6
*/
match_same_kind_tokens :: proc(
	scanner: ^Scanner,
	max_count: int,
	compare_str: string,
	token_types: []TokenType,
) -> (
	found_token: TokenType,
	token_length: int,
	ok: bool,
) {
	if len(token_types) != max_count {
		fmt.eprintln("ERROR: len(token_types) needs to be the same as max_count")
		return TokenType.ERROR, 0, false
	}

	count := max_count

	for count > 0 {
		compare_tokens := strings.repeat(compare_str, count - 1)
		defer delete(compare_tokens)

		ahead_characters := peek_multiple(scanner, count - 1)

		if ahead_characters == compare_tokens {
			found_token = token_types[count - 1]

			return found_token, count - 1, true
		}

		count -= 1
	}

	fmt.eprintln("ERROR: Couldn't match any tokens, check your condition.")
	return TokenType.ERROR, 0, false
}

is_at_end :: proc {
	is_at_end_scanner,
	is_at_end_index,
}

is_at_end_scanner :: proc(scanner: ^Scanner) -> bool {
	at_end := cast(int)scanner.current >= scanner.source_len

	return at_end
}

is_at_end_index :: proc(scanner: ^Scanner, index: int) -> bool {
	at_end := index >= scanner.source_len

	return at_end

}

print_token :: proc(token: Token) {
	if name, ok := reflect.enum_name_from_value(token.type); ok {
		if token.type == TokenType.TEXT {
			fmt.printf("%v('%v')", name, token.content)
		} else if token.type == TokenType.LINK || token.type == TokenType.IMAGE {
			fmt.printf("%v('%v' : '%v')", name, token.content, token.link)
		} else {
			fmt.print(name)
		}
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
