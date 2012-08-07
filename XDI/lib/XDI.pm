package XDI;

use 5.006;
use strict;
use warnings;

use Carp;
use Log::Log4perl qw(get_logger :levels);
use JSON::XS;
use Data::Dumper;
use Data::UUID;
use Storable qw(dclone);
use Clone qw(clone);

use XDI::Connection;

require Exporter;
use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

# set the version for version checking
$VERSION     = 0.01;

@ISA         = qw(Exporter);
@EXPORT      = qw();
%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

# your exported package globals go here,
# as well as any optionally exported functions
#@EXPORT_OK   = qw($Var1 %Hashit &func3);
#use vars qw($Var1 %Hashit);

@EXPORT_OK   = qw(&s_debug);
use vars qw();

# non-exported package globals go here
#use vars      qw(@more $stuff);
use vars      qw();

# file-private lexicals go here
my %fields = (
	from_graph => undef,
	from => undef,
);

our $AUTOLOAD;
our $USE_LOCAL_MESSAGE = 1;

sub new {
	my $class  = shift;
	my $self = {%fields,};
	bless($self,$class);
	my ($var_hash) = @_;
	if (defined $var_hash  ) {
		if (ref $var_hash eq "HASH"){
			foreach my $varkey (keys %{$var_hash}) {
				if (exists $self->{$varkey}) {
					$self->{$varkey} = $var_hash->{$varkey};
				}
			}
		} elsif (ref $var_hash eq "") {
			#TODO: resolve iname into iname/inumber
			$self->{'from'} = $var_hash;
			$self->{'from_graph'} = $var_hash;
		} else {
		croak "Initialization failed: parameters not passed as hash reference or iname string";
		}
	} 
	return $self;
}


sub AUTOLOAD {
	my $self   = shift;
	my $type   = ref($self)
	  or croak "($AUTOLOAD): $self is not an object";
	my $name = $AUTOLOAD;
	$name =~ s/.*://;
	unless ( exists $self->{$name} ) {
		carp "$name not permitted in class $type";
		return;
	}

	if (@_) {
		my $obj = shift;
		if ( ref $obj ne "" ) {
			return $self->{$name} = dclone $obj;
		}
		else {
			return $self->{$name} = $obj;
		}

	}
	else {
		return $self->{$name};
	}
}

sub connect {
	my $self = shift;
	my $connector = XDI::Connection->new($self,@_);
	return $connector;
}

sub pick_xdi_tuple {
	my ($graph,$match) = @_;
	my $logger = get_logger();
	$logger->debug("Match: ", sub {Dumper($match)});
	foreach my $key (keys %{$graph}) {
		my ($subject,$predicate,$value);
		if ($key =~ m/^(.+)\/(.+)$/) {
			$subject = $1;
			$predicate = $2;
			$value = $graph->{$key}->[0];
			my $ret = 1;
			if (defined $match->[0] && $match->[0] ne $subject) {
				$ret = 0;
			}
			if ($ret && defined $match->[1] && $match->[1] ne $predicate) {
				$ret = 0
			}
			if ($ret && defined $match->[2] && $match->[2] ne $value) {
				$ret = 0;
			}
			if ($ret) {
				return [$subject,$predicate,$value];
			}
		}
	}
	return undef;
	
}

# Hopefully this will get more sophisticated
sub is_inumber {
	my ($xdi) = @_;
	return $xdi =~ m/!/;
}



sub s_debug {
	my $parent = (caller(0))[0];
	my $sub = (caller(1))[3];
	return ($parent,$sub);
}

sub _decode {
	my ($string) = @_;
	my $logger = get_logger();
	my $struct;
	eval {
		$struct = JSON::XS::->new->pretty(1)->decode($string);
	};
	if ($@ && not defined $struct) {
		carp("Not a valid JSON string");
	} else {
		return $struct;
	}
}


sub DESTROY { }

END { }       # module clean-up code here (global destructor)



=head1 NAME

XDI - The great new XDI!

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';


=head1 SYNOPSIS

Quick summary of what the module does.

Perhaps a little code snippet.

    use XDI;

    my $foo = XDI->new();
    ...

=head1 EXPORT

A list of functions that can be exported.  You can delete this section
if you don't export anything, such as for a purely object-oriented module.

=head1 SUBROUTINES/METHODS

=head2 function1

=cut

sub function1 {
}

=head2 function2

=cut

sub function2 {
}

=head1 AUTHOR

Mark Horstmeier, C<< <solargroovey at gmail.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-xdi at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=XDI>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc XDI


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=XDI>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/XDI>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/XDI>

=item * Search CPAN

L<http://search.cpan.org/dist/XDI/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2012 Mark Horstmeier.

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; version 2 dated June, 1991 or at your option
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

A copy of the GNU General Public License is available in the source tree;
if not, write to the Free Software Foundation, Inc.,
59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.


=cut

1; # End of XDI
