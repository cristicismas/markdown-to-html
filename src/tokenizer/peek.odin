package tokenizer

import "core:fmt"
import "core:slice"
import "core:unicode/utf8"

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

peek_until_next_sequence :: proc(
	scanner: ^Scanner,
	sequence: string,
	start_index: int,
) -> (
	result: string,
	ok: bool,
) {
	search_index := start_index

	for !is_at_end(scanner, search_index - 1) {
		sequence_at_index := get_sequence_at_index(
			scanner.source,
			utf8.rune_count(sequence),
			search_index,
		)

		if sequence_at_index == "```" {
			return scanner.source[scanner.current:search_index], true
		} else {
			delete(sequence_at_index)
		}
		search_index += 1
	}

	return "", false
}

get_sequence_at_index :: proc(source: string, sequence_len: int, start_index: int) -> string {
	runes := make([dynamic]rune, 0, sequence_len, context.temp_allocator)

	index := 0

	for index < sequence_len {
		rune_at_index := utf8.rune_at_pos(source, index + start_index)

		if rune_at_index == utf8.RUNE_ERROR {
			return ""
		}

		append(&runes, rune_at_index)
		index += 1
	}

	return utf8.runes_to_string(runes[:])
}
