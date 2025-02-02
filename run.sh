odin build src/ -debug -out:bin/output

# Check if the compilation was successful
if [ $? -eq 0 ]; then
    # Run the compiled program with all arguments passed to the script
    bin/output "$@"
else
    echo "Compilation failed."
    exit 1
fi
