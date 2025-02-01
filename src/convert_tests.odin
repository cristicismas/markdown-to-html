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
