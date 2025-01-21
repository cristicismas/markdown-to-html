package main

import "core:testing"

@(test)
empty_string_test :: proc(t: ^testing.T) {
	markdown := ""
	html := markdown_to_html(markdown)

	testing.expect(t, html == "")
}

@(test)
simple_h1_test :: proc(t: ^testing.T) {
	markdown := "# Simple h1 test"
	html := markdown_to_html(markdown)

	testing.expect(t, html == "<h1>Simple h1 test</h1>")
}
