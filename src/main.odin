package main

import "core:fmt"

main :: proc() {
	input_string := "This is an image with figcap: ![image_alt](https://placehold.co/600x400 \"Figure Caption\")"
	expected_html := "<p>This is an image with figcap: <img src=\"https://placehold.co/600x400\" alt=\"image_alt\" title=\"Figure Caption\"/></p>"
	html := markdown_to_html(input_string)
	fmt.println("\n HTML: ", html)
	fmt.println("\n expected: ", expected_html)
	fmt.println("\n same: ", html == expected_html)
}
