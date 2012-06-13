#!/usr/bin/perl -w

use lib qw(
	./
	../
);

use HTTP::XDI;

my $xdi1 = new HTTP::XDI;

my $hash = {
	
};

my $xdi2 = new HTTP::XDI($hash);