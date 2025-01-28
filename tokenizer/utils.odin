package tokenizer

import "core:fmt"
import "core:reflect"

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
