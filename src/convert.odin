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
	in_heading:     string,
}

Tag :: struct {
	open:  string,
	close: string,
}

Tags := map[t.TokenType]Tag {
	tt.PARAGRAPH   = {"<p>", "</p>"},
	tt.HASH_1      = {"<h1>", "</h1>"},
	tt.HASH_2      = {"<h2>", "</h2>"},
	tt.HASH_3      = {"<h3>", "</h3>"},
	tt.HASH_4      = {"<h4>", "</h4>"},
	tt.HASH_5      = {"<h5>", "</h5>"},
	tt.HASH_6      = {"<h6>", "</h6>"},
	tt.BOLD        = {"<b>", "</b>"},
	tt.ITALIC      = {"<i>", "</i>"},
	tt.BOLD_ITALIC = {"<b><i>", "</i></b>"},
	tt.NEW_LINE    = {"<br />", ""},
	tt.QUOTE       = {"<blockquote>", "</blockquote>"},
	tt.CODE        = {"<pre><code>", "</code></pre>"},
	tt.LINK        = {"<a>", "</a>"},
	tt.IMAGE       = {"<img>", "</img>"},
}

markdown_to_html :: proc(markdown: string) -> (html: string) {
	tokens := t.tokenize(markdown)
	fmt.println("tokens: ", tokens)

	conversion_state := ConversionState{}

	builder := strings.builder_make(context.temp_allocator)
	defer strings.builder_destroy(&builder)

	for token in tokens {
		switch token.type {
		case t.TokenType.TEXT:
			strings.write_string(&builder, token.content)
		case t.TokenType.PARAGRAPH:
			open_or_close_bracket(conversion_state.in_paragraph, &builder, Tags[token.type])
			conversion_state.in_paragraph = !conversion_state.in_paragraph
		case t.TokenType.HASH_1:
		case t.TokenType.HASH_2:
		case t.TokenType.HASH_3:
		case t.TokenType.HASH_4:
		case t.TokenType.HASH_5:
		case t.TokenType.HASH_6:
		case t.TokenType.BOLD:
			open_or_close_bracket(conversion_state.in_bold, &builder, Tags[token.type])
			conversion_state.in_bold = !conversion_state.in_bold
		case t.TokenType.ITALIC:
		case t.TokenType.BOLD_ITALIC:
		case t.TokenType.DASH:
		case t.TokenType.NEW_LINE:
			if conversion_state.in_paragraph {
				strings.write_string(&builder, Tags[tt.PARAGRAPH].close)
			}
		case t.TokenType.EOF:
			if conversion_state.in_paragraph {
				strings.write_string(&builder, Tags[tt.PARAGRAPH].close)
			}
		case t.TokenType.QUOTE:
		case t.TokenType.CODE:
		case t.TokenType.CODE_BLOCK:
		case t.TokenType.LINK:
		case t.TokenType.IMAGE:
		case t.TokenType.ERROR:
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
