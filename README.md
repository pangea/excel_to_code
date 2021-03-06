# excel_to_code

Converts some excel spreadsheets (.xlsx, not .xls) into some other programming languages (currently ruby or c).
This allows the excel spreadsheets to be run programatically, without excel.

Its cannonical source is at http://github.com/tamc/excel_to_code

# Running excel_to_code

To just have a go:

	./bin/excel_to_c <excel_file_name>
	
NB:For small spreadsheets this will take a minute or so. For large spreadsheets it is best to run it overnight.
	
for more detail:
	
	./bin/excel_to_c --compile --run-tests --settable <name of input worksheet> --prune-except <name of output worksheet> <excel file name> 
	
this should work:

	./bin/excel_to_c --help

# Testing excel_to_code

1. Make sure you have ruby 1.9.2 or later installed
2. gem install bundler # May need to use sudo
3. bundle
4. rspec spec/*

To test the C runtime:
1. cd src/compile/c
2. cc excel_to_c_runtime
3. ./a.out

# Hacking excel_to_code

There are some how to guides in the doc folder. 

# Limitations

1. Not tested at all on Windows
2. INDIRECT and OFFSET formula must be convertable at runtime into a standard formula
3. Doesn't implement all functions (see doc/Which_functions_are_implemented.md)
4. Doesn't implement references that involve range unions and lists (but does implement standard ranges)
5. Sometimes gives cells as being empty, when excel would give the cell as having a numeric value of zero
6. The generated C version does not multithread and will give bad results if you try
7. The generated code uses floating point, rather than fully precise arithmetic, so results can differ slightly
8. The generated code uses the sprintf approach to rounding (even-odd) rather than excel's 0.5 rounds away from zero.
90. Ranges like this: Sheet1!A10:Sheet1!B20 and 3D ranges don't work
