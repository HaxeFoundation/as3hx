#!/usr/bin/perl

# This program fixes files that have haxe property getter/setter names that
# are not haxe 3 compliant.  In haxe 3, property getters must be named
# get_x, where x is the name of the variable.  Similarly, property setters
# must be named set_x.
#
# All arguments are file names of haxe files to process, or "-l" to turn
# on special behavior.
#
# If run with the -l option, this program just prints out the name of any
# of its input files that would need to be fixed up.  This allows a two
# step process where this program is first run to identify the names of
# all files that need to be modified (allowing them to be p4 opened), and
# then a second run (without the -l option) to actually do the work.

use File::Copy qw/ copy /;
use File::Temp qw/ tempfile /;

$opt_l = 0;

LOOP: foreach $argnum (0 .. $#ARGV)
{
	$filename = $ARGV[$argnum];

	if ($filename eq "-l") {
		$opt_l = 1;
		next LOOP;
	}

	open FILE, "<$filename" || die "Can't open input file $filename";

    # Pass 1: Search for property names
	%getters = ();
	%setters = ();

	while (<FILE>)
	{
		if (/.*var\s+(.*)\((.*),(.*)\)/) {
			$varname = $1;
			$getter = $2;
			$setter = $3;
			# Remove comments
			$varname =~ s/\/\*.*\*\///g;
			$getter =~ s/\/\*.*\*\///g;
			$setter =~ s/\/\*.*\*\///g;
			# Trim whitespace
			$varname =~ s/^\s+|\s+$//g;
			$getter =~ s/^\s+|\s+$//g;
			$setter =~ s/^\s+|\s+$//g;
			# Skip any variable which had whitespace in it, it wasn't a
			# valid variable
			if ($varname !~ /\s/) {
				if ($getter !~ /(default|dynamic|null|never|get_$varname)/) {
					$getters{$varname} = $getter;
				}
				if ($setter !~ /(default|dynamic|null|never|set_$varname)/) {
					$setters{$varname} = $setter;
				}
			}
		}
	}
	
	close FILE;

	# Skip the file if it doesn't even have properties that need to be
	# modified
	next LOOP unless (keys(%getters) || keys(%setters));

    # If -l option was specified, just print out the name of the file if
	# it has noncompliant getters or setters
	if ($opt_l) {
		print "$filename\n";
		next LOOP;
	}

	# Pass 2: Replace the getters and setters into a temporary file

	open FILE, "<$filename" || die "Can't open input file $filename";

	($tmpfh, $tmpfname) = tempfile();

	while (<FILE>) {
		$line = $_;
		for my $key (keys %getters) {
			$oldgetter = $getters{$key};
			$line =~ s/$oldgetter /get_$key /g;
			$line =~ s/$oldgetter,/get_$key,/g;
			$line =~ s/$oldgetter\(/get_$key\(/g;
		}
		for my $key (keys %setters) {
			$oldsetter = $setters{$key};
			$line =~ s/$oldsetter /set_$key /g;
			$line =~ s/$oldsetter,/set_$key,/g;
			$line =~ s/$oldsetter\(/set_$key\(/g;
			$line =~ s/$oldsetter\)/set_$key\)/g;
		}
		print $tmpfh $line;
	}

	close $tmpfh;

	close FILE;

	copy $tmpfname, $filename;

	unlink $tmpfname;
}
