package HTTP::XDI;  
# file HTTP/XDI.pm

use strict;
use Carp;

require Exporter;
use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

# set the version for version checking
$VERSION     = 0.01;

@ISA         = qw(Exporter);
@EXPORT      = qw(&get &mod &del &add);
%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

# your exported package globals go here,
# as well as any optionally exported functions
#@EXPORT_OK   = qw($Var1 %Hashit &func3);
#use vars qw($Var1 %Hashit);

@EXPORT_OK   = qw();
use vars qw($Var1 %Hashit);

# non-exported package globals go here
#use vars      qw(@more $stuff);
use vars      qw();

# initialize package globals, first exported ones
#$Var1   = '';
#%Hashit = ();

# then the others (which are still accessible as $Some::Module::stuff)
#$stuff  = '';
#@more   = ();

# all file-scoped lexicals must be created before
# the functions below that use them.

# file-private lexicals go here
my %fields = (
	from_graph => undef,
	from => undef,
	to	=> undef,
	id => undef,
	to_graph => undef	
);


our $AUTOLOAD;

# here's a file-private function as a closure,
# callable as &$priv_func.
#my $priv_func = sub {
#    # stuff goes here.
#};

# make all your functions, whether exported or not;
# remember to put something interesting in the {} stubs
#sub func1      { .... }    # no prototype
#sub func2()    { .... }    # proto'd void
#sub func3($$)  { .... }    # proto'd to 2 scalars



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
		} else {
		croak "Initialization failed: parameters not passed as hash reference";
		}
	} 
	return $self;
}

sub connect {
	my $self = shift;
	my $var_hash = shift;
	my $source = $self->{'from_graph'};
	if (defined $var_hash) {
		
	}
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

sub DESTROY { }

# this one isn't auto-exported, but could be called!
#sub func4(\%)  { .... }    # proto'd to 1 hash ref

END { }       # module clean-up code here (global destructor)

1;
