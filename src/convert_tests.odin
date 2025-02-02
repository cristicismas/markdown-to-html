package main

import "core:testing"

@(test)
convert_link_test :: proc(t: ^testing.T) {
	input_string := "This is a [link](https://www.google.com)"
	html := markdown_to_html(input_string)

	expected_html := "<p>This is a <a href=\"https://www.google.com\">link</a></p>"

	testing.expect(t, html == expected_html)
}

@(test)
convert_image_test :: proc(t: ^testing.T) {
	input_string := "This is an image: ![image_alt](https://placehold.co/600x400)"
	html := markdown_to_html(input_string)

	expected_html := "<p>This is an image: <img src=\"https://placehold.co/600x400\" alt=\"image_alt\"/></p>"

	testing.expect(t, html == expected_html)
}

@(test)
convert_image_figcap_test :: proc(t: ^testing.T) {
	input_string := "This is an image with figcap: ![image_alt](https://placehold.co/600x400 \"Figure Caption\")"
	html := markdown_to_html(input_string)

	expected_html := "<p>This is an image with figcap: <img src=\"https://placehold.co/600x400\" alt=\"image_alt\" title=\"Figure Caption\"/></p>"

	testing.expect(t, html == expected_html)
}

@(test)
convert_code_block_test :: proc(t: ^testing.T) {
	input_string := "```\nThis is a \ncode block\nwith multiple\nlines```"
	html := markdown_to_html(input_string)
	expected_html := "<pre><code>This is a \ncode block\nwith multiple\nlines</code></pre>"

	testing.expect(t, html == expected_html)
}

@(test)
convert_unordered_list_with_line_breaks :: proc(t: ^testing.T) {
	input_string := "Here is a list: \n- first\n- second\n- third with __bold__\n\n\nList has ended!"
	html := markdown_to_html(input_string)

	expected_html := "<p>Here is a list: <br /><ul><li>first</li><li>second</li><li>third with <b>bold</b></li></ul></p><br /><br /><p>List has ended!</p>"
	testing.expect(t, html == expected_html)
}

@(test)
convert_ordered_list_with_line_breaks :: proc(t: ^testing.T) {
	input_string := "Here is a list: \n1. first\n2. second\n3. third with __bold__\n\n\nList has ended!"
	html := markdown_to_html(input_string)

	expected_html := "<p>Here is a list: <br /><ol><li>first</li><li>second</li><li>third with <b>bold</b></li></ol></p><br /><br /><p>List has ended!</p>"
	testing.expect(t, html == expected_html)
}
