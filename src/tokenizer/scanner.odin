package tokenizer

import "core:fmt"
import "core:strings"

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
scan_same_kind_tokens :: proc(
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
