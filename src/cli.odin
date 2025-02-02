package main

import "core:fmt"
import "core:os"
import "core:strings"

USAGE_INFO :: `
Usage: md_to_html [path_to_markdown] [path_to_html]

If [path_to_html] is not specified, the program will create an "output.html" file in the 
directory where the program was called from.

`


cli_init :: proc() {
	if len(os.args) < 2 || len(os.args) > 4 {
		fmt.eprintln(
			"Invalid arg count passed to program. Please find the usage instructions below:",
		)
		fmt.eprintln(USAGE_INFO)
		os.exit(1)
	}

	if os.args[1] == "help" || os.args[1] == "--help" {
		fmt.println(USAGE_INFO)
		os.exit(0)
	}

	markdown_file := os.args[1]
	output_file := len(os.args) == 3 && os.args[2] != "--force" ? os.args[2] : "output.html"
	force_flag := len(os.args) == 4 ? os.args[3] == "--force" : false
	if len(os.args) == 3 && os.args[2] == "--force" {
		force_flag = true
	}

	if os.exists(output_file) && !force_flag {
		fmt.eprintfln(
			"Cannot run this program when another file with the \"%v\" name already exists. Please choose another output name for your html file.\nAlternatively, you can choose to override this check with the --force flag (please be ware that this will override the content in the output file).",
			output_file,
		)
		os.exit(1)
	}


	html := try_convert_file(markdown_file)
	write_ok := os.write_entire_file(output_file, transmute([]u8)html)
	if !write_ok {
		fmt.eprintfln(
			"Failed to write to file: %v. Please make sure the path exists and that you are using the program correctly:",
			output_file,
		)
		fmt.eprintln(USAGE_INFO)
	}

	fmt.printfln(
		"Successfully converted markdown to html, from \"%v\" to \"%v\"",
		markdown_file,
		output_file,
	)
}

try_convert_file :: proc(file_path: string) -> (html: string) {
	file_data, read_ok := os.read_entire_file(file_path)

	if !read_ok {
		fmt.eprintfln(
			"Failed to read content from: %v. Please make sure the path exists and that you are using the program correctly:",
			file_path,
		)
		fmt.eprintln(USAGE_INFO)
		os.exit(1)
	}

	html = markdown_to_html(string(file_data))

	return html
}
