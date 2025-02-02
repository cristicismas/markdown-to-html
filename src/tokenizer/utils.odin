package tokenizer

import "core:fmt"
import "core:reflect"
import "core:unicode"

print_token :: proc(token: Token) {
	if name, ok := reflect.enum_name_from_value(token.type); ok {
		if token.type == TokenType.TEXT || token.type == TokenType.CODE_BLOCK {
			fmt.printf("%v('%v')", name, token.content)
		} else if token.type == TokenType.LINK || token.type == TokenType.IMAGE {
			fmt.printf("%v('%v' : '%v')", name, token.content, token.link)
		} else {
			fmt.print(name)
		}
	}
}

print_tokens :: proc(tokens: []Token, on_separate_lines: bool = false) {
	for token, i in tokens {
		if on_separate_lines {
			fmt.printf("line %v: ", token.line)
		}

		print_token(token)

		if i < len(tokens) - 1 && !on_separate_lines {
			fmt.print(", ")
		} else {
			fmt.print("\n")
		}
	}
}

print_token_differences :: proc(first: []Token, second: []Token) {
	if len(first) != len(second) {
		fmt.printfln(
			"-- len(first) is not equal to len(second). len(first) == %v, len(second) == %v",
			len(first),
			len(second),
		)
		return
	}

	for token, i in first {
		if token != second[i] {
			fmt.printfln("-- Token '%v' is different from: '%v'", token, second[i])
		}
	}
}

compare_token_slices :: proc(first: []Token, second: []Token) -> (are_equal: bool) {
	if len(first) != len(second) {
		fmt.eprintfln(
			"ERROR: Slice lengths are not equal. first len: %v; second len: %v",
			len(first),
			len(second),
		)
		return false
	}

	for token, i in first {
		if second[i] != token {
			print_token_differences(first, second)
			return false
		}
	}

	return true
}

// Check if the last 2 tokens were line breaks
check_is_paragraph :: proc(scanner: ^Scanner) -> bool {
	if len(scanner.tokens) > 1 {
		prev_tokens := scanner.tokens[len(scanner.tokens) - 2:]

		if prev_tokens[0].type == TokenType.NEW_LINE && prev_tokens[1].type == TokenType.NEW_LINE {
			return true
		}
	} else if len(scanner.tokens) == 1 {
		prev_token := scanner.tokens[0]

		if prev_token.type == TokenType.NEW_LINE {
			return true
		}
	} else {
		return true
	}
	return false
}

is_numeric :: proc(s: string) -> bool {
	for char in s {
		if !unicode.is_number(char) {
			return false
		}
	}

	return true
}
