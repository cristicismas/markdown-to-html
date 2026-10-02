package main

import "core:fmt"
import os "core:os/old"

USAGE_INFO :: `
Usage: md_to_html [path_to_markdown] [path_to_html] [force_flag]

- path_to_markdown: path to the markdown file you wish to convert

- path_to_html (optional): output path of the converted html file

- force_flag ("--force"|"") (optional): If set, overrides the check for already existing output files, overriding whatever is in the path_to_html file.

- inline_flag ("--inline"|"") (optional): If set, outputs the html directly inline. Useful for using in bash scripts.

If [path_to_html] and [inline_flag] are not specified, the program will create an "output.html" file in the
directory where the program was called from.
`


find_flag :: proc(args: []string, flag: string) -> bool {
	for s in args {
		if s == flag {
			return true
		}
	}

	return false
}

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

	inline_flag := len(os.args) > 2 && find_flag(os.args, "--inline")

	force_flag := len(os.args) == 4 && find_flag(os.args, "--force")

	output_file := len(os.args) == 3 && os.args[2] != "--force" ? os.args[2] : "output.html"

	if inline_flag {
		output_file = ""
	}

	if len(os.args) == 3 && os.args[2] == "--force" {
		force_flag = true
	}

	if os.exists(output_file) && !force_flag && !inline_flag {
		fmt.eprintfln(
			"Cannot run this program when another file with the \"%v\" name already exists. Please choose another output name for your html file.\nAlternatively, you can choose to override this check with the --force flag (please be ware that this will override the content in the output file).",
			output_file,
		)
		os.exit(1)
	}

	html := try_convert_file(markdown_file)

	if (inline_flag) {
		fmt.print(html)
	} else {
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
