
Yannick,

Please find enclosed the files that you'll need to get started on the
'as3tohx' project.

The basic task is to improve the as3tohx program such that running it
on the test input AS3 file (conversionTest.as) produces exactly the
output in the "golden" test results file (conversionTest_golden.hx).
For this task, seemingly trivial things like the whitespace in the
output is important as we want to use this tool to convert our large
AS3 code base and preserve, as much as possible, the code's compliance
to our coding conventions.

A manifest is included below with a list of the files that should be
included and, for each, their purpose.  Also, see the section below on
running the conversion workflow (including "sed" scripts) on the test
file.

If you have any questions, feel free to contact us.  It is probably
best and easiest to start by contacting Alfred.

The TiVo Team  ;)

  Alfred Barberena (abarberena@tivo.com)
  Todd Kulick (kulick@tivo.com)
  Richard Lee (rdlee@tivo.com)


MANIFEST
----------------------------------------------------------------------

  # Most important files...
  README_FIRST.txt                This file
  convert.sh                      Script embodying our workflow
  as3hx_config.xml		  Config file for as3hx

  # Our test files...
  test/conversionTest.as          TiVo test AS3 file to be converted
  test/conversionTest_before.hx   Current output of converting test file
  test/conversionTest_golden.hx   TiVo Golden output file (in Haxe)

  # Distribution of as3tohx (w/minor TiVo mods)
  as3hx/                          Source package for as3hx
  as3hx/as3hx.hxml                Build file for as3hx
  as3hx/test/...                  as3hx packaged tests
  as3hx/...                       Remainder of as3hx

  # Maybe useful files as project progresses...
  README_haxe3_todo.txt           Some AS3 -> Haxe3 conversion notes
  as3tidy.sed                     Pre-convert "sed" script
  as3posttidy.sed		  Post-convert "sed" script
  clean.sh                        Clean up after convert.sh
  fix_haxe_properties.pl          Perl script to handle Haxe3 properties


CONVERSION WORKFLOW
----------------------------------------------------------------------

To convert the test file and see the results of comparing it to the
golden file, you can run the 'convert.sh' script...

  $ cd <to_where_this_file_is>
  $ ./convert.sh

The output for me looks like this...

  $ cbe ./convert.sh
  /home/kulick/as3tohx_project/test.as3tidy/conversionTest.as
  /home/kulick/as3tohx_project/test.hx/com/as3tohx/test/ConversionTest.hx

  WARNING: Required constructor was added for member var initialization
          /home/kulick/as3tohx_project/test.hx/com/as3tohx/test/ConversionTest.hx

  Comparing results...
  Files match golden!

When the results don't match, the convert.sh script will dump out the
differences.


NEKO and HAXE 3
----------------------------------------------------------------------

I'm assuming that you have Neko 2 and Haxe 3 installed already.


REBUILDING as3tohx
----------------------------------------------------------------------

If you run the 'buildme' script in the 'as3hx/' subdirectory, it
should rebuild the as3tohx executable.  It is currently set to build a
neko byte code file and then link that up with the neko interpreter to
generate the executable.

If you check out the 'buildme' script, you can see how we're building
'as3tohx'.  All the code is in the 'as3hx' and 'as3hx/as3hx'
directories.


USING WINDOWS INSTEAD OF LINUX
----------------------------------------------------------------------

Since you might want to do this on Windows, I'm including the
following quick description in the hope that it will be helpful...

As we mentioned on the conference call, our conversion workflow
actually has three steps: a "sed" script-based pre-conversion step,
the actual as3tohx program conversion, and a "sed" script-based
post-conversion step.  We have included a bash shell script called
'convert.sh' that embodies and executes this workflow.

Sorry for the Linux-isms, but that is kind of how we "roll" around
here.  You should be able to build and execute the as3tohx program on
Windows without too much trouble by looking at our scripts and
mimicing them.  Alternatively, you can set up a Linux box or VM or
something.  I'm hoping you can sort this bit out.  :)

I don't think that the "sed" scripts do much that is important when
converting our test file, so you can probably ignore them altogether,
at least initially.

If you just run as3tohx like this, you should be able to get going...

  C:> as3tohx --debug-inferred-type test out

This will generate converted output under the directory 'out'.

