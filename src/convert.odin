package main
import "core:fmt"

import "core:reflect"
import "core:strings"
import "core:unicode/utf8"
import t "tokenizer"

tt :: t.TokenType

ConversionState :: struct {
	in_bold:        bool,
	in_italic:      bool,
	in_bold_italic: bool,
	in_paragraph:   bool,
	in_code:        bool,
	in_quote:       bool,
	in_ul:          bool,
	in_ol:          bool,
	in_heading:     t.TokenType,
	tokens:         []t.Token,
	current_index:  int,
}

Tag :: struct {
	open:  string,
	close: string,
}

Tags := map[t.TokenType]Tag {
	tt.PARAGRAPH    = {"<p>", "</p>"},
	tt.HASH_1       = {"<h1>", "</h1>"},
	tt.HASH_2       = {"<h2>", "</h2>"},
	tt.HASH_3       = {"<h3>", "</h3>"},
	tt.HASH_4       = {"<h4>", "</h4>"},
	tt.HASH_5       = {"<h5>", "</h5>"},
	tt.HASH_6       = {"<h6>", "</h6>"},
	tt.BOLD         = {"<b>", "</b>"},
	tt.ITALIC       = {"<i>", "</i>"},
	tt.BOLD_ITALIC  = {"<b><i>", "</i></b>"},
	tt.NEW_LINE     = {"<br />", ""},
	tt.QUOTE        = {"<blockquote>", "</blockquote>"},
	tt.CODE         = {"<pre><code>", "</code></pre>"},
	tt.CODE_BLOCK   = {"<pre><code>", "</code></pre>"},
	tt.UNORDERED_LI = {"<ul>", "</ul>"},
	tt.ORDERED_LI   = {"<ol>", "</ol>"},
	tt.LINK         = {"<a>", "</a>"},
	tt.IMAGE        = {"<img>", "</img>"},
}

markdown_to_html :: proc(markdown: string) -> (html: string) {
	tokens := t.tokenize(markdown)

	conversion_state := ConversionState {
		tokens = tokens,
	}

	builder := strings.builder_make()
	defer strings.builder_destroy(&builder)

	for token, token_index in tokens {
		conversion_state.current_index = token_index
		defer free_all(context.temp_allocator)

		switch token.type {
		case t.TokenType.TEXT:
			strings.write_string(&builder, token.content)
		case t.TokenType.PARAGRAPH:
			open_or_close_bracket(conversion_state.in_paragraph, &builder, Tags[token.type])
			conversion_state.in_paragraph = !conversion_state.in_paragraph
		case t.TokenType.HASH_1:
			strings.write_string(&builder, Tags[token.type].open)
			conversion_state.in_heading = tt.HASH_1
		case t.TokenType.HASH_2:
			strings.write_string(&builder, Tags[token.type].open)
			conversion_state.in_heading = tt.HASH_2
		case t.TokenType.HASH_3:
			strings.write_string(&builder, Tags[token.type].open)
			conversion_state.in_heading = tt.HASH_3
		case t.TokenType.HASH_4:
			strings.write_string(&builder, Tags[token.type].open)
			conversion_state.in_heading = tt.HASH_4
		case t.TokenType.HASH_5:
			strings.write_string(&builder, Tags[token.type].open)
			conversion_state.in_heading = tt.HASH_5
		case t.TokenType.HASH_6:
			strings.write_string(&builder, Tags[token.type].open)
			conversion_state.in_heading = tt.HASH_6
		case t.TokenType.BOLD:
			open_or_close_bracket(conversion_state.in_bold, &builder, Tags[token.type])
			conversion_state.in_bold = !conversion_state.in_bold
		case t.TokenType.ITALIC:
			open_or_close_bracket(conversion_state.in_italic, &builder, Tags[token.type])
			conversion_state.in_italic = !conversion_state.in_italic
		case t.TokenType.BOLD_ITALIC:
			open_or_close_bracket(conversion_state.in_bold_italic, &builder, Tags[token.type])
			conversion_state.in_bold_italic = !conversion_state.in_bold_italic
		case t.TokenType.UNORDERED_LI:
			if !conversion_state.in_ul {
				strings.write_string(&builder, Tags[tt.UNORDERED_LI].open)
				conversion_state.in_ul = true
			}

			strings.write_string(&builder, "<li>")
		case t.TokenType.ORDERED_LI:
			if !conversion_state.in_ol {
				strings.write_string(&builder, Tags[tt.ORDERED_LI].open)
				conversion_state.in_ol = true
			}

			strings.write_string(&builder, "<li>")
		case t.TokenType.NEW_LINE:
			handle_line_end_or_eof(&conversion_state, &builder)
		case t.TokenType.EOF:
			handle_line_end_or_eof(&conversion_state, &builder)
		case t.TokenType.QUOTE:
			strings.write_string(&builder, Tags[token.type].open)
			conversion_state.in_quote = true
		case t.TokenType.CODE:
			open_or_close_bracket(conversion_state.in_code, &builder, Tags[token.type])
			conversion_state.in_code = !conversion_state.in_code
		case t.TokenType.CODE_BLOCK:
			strings.write_string(&builder, Tags[token.type].open)
			strings.write_string(&builder, token.content)
			strings.write_string(&builder, Tags[token.type].close)
		case t.TokenType.LINK:
			link_tag := strings.concatenate(
				{"<a href=\"", token.link, "\">", token.content, "</a>"},
				context.temp_allocator,
			)
			strings.write_string(&builder, link_tag)
		case t.TokenType.IMAGE:
			split := strings.split(token.link, " ")
			if len(split) > 1 {
				source := split[0]
				figcap := strings.trim(strings.join(split[1:], " ", context.temp_allocator), "\"")

				image_tag := strings.concatenate(
					{
						"<img src=\"",
						source,
						"\" alt=\"",
						token.content,
						"\" title=\"",
						figcap,
						"\"/>",
					},
					context.temp_allocator,
				)

				strings.write_string(&builder, image_tag)
			} else {
				image_tag := strings.concatenate(
					{"<img src=\"", token.link, "\" alt=\"", token.content, "\"/>"},
					context.temp_allocator,
				)

				strings.write_string(&builder, image_tag)
			}
		case t.TokenType.ERROR:
			fmt.eprintln("ERROR: token.type is of type ERROR:", token)
			panic("Found ERROR type token.")
		}
	}

	html_output := strings.clone(strings.to_string(builder))

	return html_output
}

open_or_close_bracket :: proc(is_inside_bracket: bool, builder: ^strings.Builder, tag: Tag) {
	if is_inside_bracket {
		strings.write_string(builder, tag.close)
	} else {
		strings.write_string(builder, tag.open)
	}
}

handle_line_end_or_eof :: proc(conversion_state: ^ConversionState, builder: ^strings.Builder) {
	current_token := conversion_state.tokens[conversion_state.current_index]
	next_token := get_token_at_index(conversion_state.tokens, conversion_state.current_index + 1)

	has_mutated_state := false

	if conversion_state.in_heading != {} {
		heading_tag, ok := Tags[conversion_state.in_heading]

		if !ok {
			fmt.eprintln(
				"ERROR: Failed to convert heading. Found a in_heading tag that is not present on the Tags map.",
			)
			panic("CONVERSION_FAILURE")
		}

		strings.write_string(builder, heading_tag.close)
		conversion_state.in_heading = {}
		has_mutated_state = true
	}

	if conversion_state.in_quote == true {
		strings.write_string(builder, Tags[tt.QUOTE].close)
		conversion_state.in_quote = false
		has_mutated_state = true
	}

	if conversion_state.in_ul {
		strings.write_string(builder, "</li>")

		if current_token.type == tt.EOF {
			strings.write_string(builder, "</ul>")
			conversion_state.in_ul = false
		} else if next_token.type != tt.UNORDERED_LI {
			strings.write_string(builder, "</ul>")
			conversion_state.in_ul = false
		}
		has_mutated_state = true
	}

	if conversion_state.in_ol {
		strings.write_string(builder, "</li>")

		if current_token.type == tt.EOF {
			strings.write_string(builder, "</ol>")
			conversion_state.in_ol = false
		} else if next_token.type != tt.ORDERED_LI {
			strings.write_string(builder, "</ol>")
			conversion_state.in_ol = false
		}
		has_mutated_state = true
	}

	if conversion_state.in_paragraph {
		if current_token.type == tt.EOF ||
		   next_token.type == tt.EOF ||
		   next_token.type == tt.NEW_LINE {
			strings.write_string(builder, Tags[tt.PARAGRAPH].close)
			conversion_state.in_paragraph = false
			has_mutated_state = true
		}
	}

	if !has_mutated_state && current_token.type != tt.EOF {
		strings.write_string(builder, Tags[tt.NEW_LINE].open)
	}
}

get_token_at_index :: proc(tokens: []t.Token, index: int) -> t.Token {
	if len(tokens) <= index && index >= 0 {
		return t.Token{type = t.TokenType.ERROR}
	}

	return tokens[index]
}
