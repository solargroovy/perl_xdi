package XDI::Message;

use strict;

use Carp;
use Log::Log4perl qw(get_logger :levels);
use Data::Dumper;
use Storable qw(dclone);
use Scalar::Util;
use Data::UUID;
use DateTime::Format::RFC3339;

require Exporter;
use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

# set the version for version checking
$VERSION     = 0.01;

@ISA         = qw(Exporter);
@EXPORT      = qw();
%EXPORT_TAGS = ( );     # eg: TAG => [ qw!name1 name2! ],

# your exported package globals go here,
# as well as any optionally exported functions
@EXPORT_OK   = qw();


my %fields = (
	id => undef,
	timestamp => undef,
	from_graph => undef,
	from => undef,
	target => undef,
	link_contract => undef,
	secret => undef,
	operations => undef,
	type => undef
);


our $AUTOLOAD;
our $USE_LOCAL_MESSAGE = 1;

sub new {
	my $class  = shift;
	my $self = {%fields,};
	bless($self,$class);
	my $ug = new Data::UUID;
	$self->{'id'} = $ug->create_str() ;
	$self->{'timestamp'} = &_timestamp;
	$self->{'operations'} = [];
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

sub get {
	my $self = shift;
	my $statement = shift;
	my $op = '$get';
	return $self->_add_op($op,$statement);
}

sub add {
	my $self = shift;
	my $statement = shift;
	my $op = '$add';
	return $self->_add_op($op,$statement);
}

sub mod {
	my $self = shift;
	my $statement = shift;
	my $op = '$mod';
	return $self->_add_op($op,$statement);
}

sub del {
	my $self = shift;
	my $statement = shift;
	my $op = '$del';
	return $self->_add_op($op,$statement);
}

sub to_string {
	my $self = shift;
	my @statements;
	push(@statements,$self->_local_requestor);
	push(@statements,$self->_destination);
	push(@statements,$self->_timestamp_statement);
	push(@statements,$self->_link_contract);
	if (defined $self->secret) {
		push(@statements, $self->_auth_statement)
	}
	foreach my $op (@{$self->operations}) {
		push(@statements,$self->_operation($self->type,$op));
	}
	return (join("\n",@statements));	
}

sub _id {
	my $self = shift;
	my $id = '$(!' . $self->id . ')';
	return $id;
}

sub _timestamp {
	my $now = DateTime->now;
	my $f = DateTime::Format::RFC3339->new();
	my $ts = $f->format_datetime($now);
	return $ts;
}

sub _local_requestor {
	my $self = shift;
	my $string = "(" . $self->from_graph . ')/$add/' . $self->from . '$($msg)'. $self->_id;
	return $string;
}

sub _destination {
	my $self = shift;
	my $string = $self->from . '$($msg)' . $self->_id . '/$is()/(' . $self->target . ')';
	return $string;
}

sub _timestamp_statement {
	my $self = shift;
	my $string = $self->from_graph . '$($msg)' . $self->_id . '$d/!/(data:,' . $self->timestamp . ')';
	return $string;
}

sub _link_contract {
	my $self = shift;
	my $string = $self->from_graph . '$($msg)' . $self->_id . '/$do/' . $self->link_contract . '$do';
	return $string;
}

sub _operation {
	my $self = shift;
	my ($op,$statement) = @_;
	my $string =  $self->from_graph . '$($msg)' . $self->_id . '$do/' . $op . '/' . $statement;
	return $string;
}

sub _auth_statement {
	my $self = shift;
	my $string = $self->from_graph . '$($msg)' . $self->_id .'$secret$!($token)/!/(data:,' . $self->secret . ')';
	return $string;
}

sub _add_op {
	my $self = shift;
	my ($op,$statement) = @_;
	if (! defined $self->type) {
		$self->type($op);
	} elsif ($self->type ne $op) {
		carp "XDI message may only carry one type of operations: $op($self->{'type'})";
		return 0;
	} 
	push(@{$self->operations}, $statement);	
	return 1;
}


sub DESTROY { }


END { }       # module clean-up code here (global destructor)

1;


