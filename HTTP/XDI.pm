package HTTP::XDI;  
# file HTTP/XDI.pm

use strict;
use Carp;
use Log::Log4perl qw(get_logger :levels);
use JSON::XS;
use Data::Dumper;
use Data::UUID;
use Storable qw(dclone);
use DateTime::Format::RFC3339;
use HTTP::Request;
use LWP::UserAgent;
use Clone qw(clone);

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
	id => undef,
	link_contract=> undef,
	to_graph => undef	
);


our $AUTOLOAD;
our $USE_LOCAL_MESSAGE = 1;


sub new {
	my $class  = shift;
	my $self = {%fields,};
	bless($self,$class);
	my $ug = new Data::UUID;
	$self->{'id'} = $ug->create_str();
	$self->{'_count_'} = 0;
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

# TODO: make the validate operation smarter than just checking for existence
sub validate {
	my $self = shift;
	my $valid = 1;
	foreach my $key (keys %fields) {
		if (! defined $self->{$key}) {
			carp "Value required for element $key";
			$valid = 0;
		}
	}
	return $valid;
}


# Connect will delete any existing statements and re-create the
# XDI preamble
sub connect {
	my $self = shift;
	my @statements = ();
	if ($self->validate) {
		my $id = $self->_get_message_id;
		push (@statements,$self->_local_requestor($id));
		push (@statements,$self->_target_graph($id));
		push (@statements,$self->_timestamp($id));
		push (@statements,$self->_link_contract($id));
	}
	$self->{"_preamble_"} = \@statements;
	# TODO: check the XDI {from} assertion
	$self->set_server_url( $self->_get_server_uri());
	return 1;	
}


sub post {
	my $self = shift;
	my $logger = get_logger();
	$logger->debug("Post");
	my $server = $self->{"_server_"};
	$logger->debug("Got server: $server");
	return _post($server,$self->_make_message);
}


sub _make_message {
	my $self = shift;
	my $logger = get_logger();
	my $msg = "";
	my $pre = $self->{"_preamble_"};
	$logger->debug("Pre: ", sub {Dumper($pre)});
	my $operations = $self->{"_operations_"};
	$logger->debug("OPS: ", sub {Dumper($operations)});
	my @statements = (@$pre,@$operations);
	return join("\n",@statements);
}

sub _post {
	my ($server, $body) = @_;
	my $logger = get_logger();
	my $request = HTTP::Request->new( 'POST', $server);
	my $ua = new LWP::UserAgent;
	$logger->debug("Server: ", $server);
	$logger->debug("Body: ", $body);
	$request->content($body);
	my $response = $ua->request($request);
	my $code = $response->code;
	my $content = $response->content;
	$logger->debug("Content: $content");
	return $content;
}

sub get {
	my $self = shift;
	my ($operation) = @_;
	my $logger = get_logger();
	my $new_ops = ();
	my $ops = $self->{"_operations_"} || [];
	if (ref $operation eq "") {
		my $op_string = $self->_op_statement('$get',$operation);
		push(@$new_ops,$op_string);
		$self->{"_operations_"} = \(@$ops,@$new_ops);
		return $op_string;
	} elsif (ref $operation eq "HASH") {
		my $rstring = "";
		foreach my $op (@$operation) {
			my $op_string = $self->_op_statement('$get',$op);
			$rstring .= $op_string . "\n";
			push(@$new_ops,$op_string);			
		}
		$self->{"_operations_"} = \(@$ops,@$new_ops);
		return $rstring;
	}
	return undef;
}


sub add {
	my $self = shift;
	my ($operation) = @_;
	my $logger = get_logger();
	my $new_ops = ();
	$logger->debug("Existing ops: ", sub {Dumper($self->{"_operations_"})}, ref $self->{"_operations_"});
	my $ops = $self->{"_operations_"} || [];
	$logger->debug("Beginning ops: ", sub {Dumper($ops)}, ref $ops);
	if (ref $operation eq "") {
		my $op_string = $self->_op_statement('$add','(' . $operation . ')');
		push(@$new_ops,$op_string);
		$logger->debug("New ops: ", sub {Dumper($new_ops)}, ref $new_ops);
		my @new_ref = (@{$ops},@{$new_ops});
		$self->{"_operations_"} = \@new_ref;
		$logger->debug("Self: ", sub {Dumper(@new_ref)});
		return $op_string;
	} elsif (ref $operation eq "HASH") {
		my $rstring = "";
		foreach my $op (@$operation) {
			my $op_string = $self->_op_statement('$add',$op);
			$rstring .= $op_string . "\n";
			push(@$new_ops,$op_string);			
		}
		$self->{"_operations_"} = \(@$ops,@$new_ops);
		return $rstring;
	}
	return undef;
	
}

sub mod {
	my $self = shift;
	my ($operation) = @_;
	my $logger = get_logger();
	my $new_ops = ();
	my $ops = $self->{"_operations_"} || [];
	if (ref $operation eq "") {
		my $op_string = $self->_op_statement('$mod',$operation);
		push(@$new_ops,$op_string);
		$self->{"_operations_"} = \(@$ops,@$new_ops);
		return $op_string;
	} elsif (ref $operation eq "HASH") {
		my $rstring = "";
		foreach my $op (@$operation) {
			my $op_string = $self->_op_statement('$mod',$op);
			$rstring .= $op_string . "\n";
			push(@$new_ops,$op_string);			
		}
		$self->{"_operations_"} = \(@$ops,@$new_ops);
		return $rstring;
	}
	return undef;
	
}

sub del {
	my $self = shift;
	my ($operation) = @_;
	my $logger = get_logger();
	my $new_ops = ();
	my $ops = $self->{"_operations_"} || [];
	if (ref $operation eq "") {
		my $op_string = $self->_op_statement('$del',$operation);
		push(@$new_ops,$op_string);
		$self->{"_operations_"} = \(@$ops,@$new_ops);
		return $op_string;
	} elsif (ref $operation eq "HASH") {
		my $rstring = "";
		foreach my $op (@$operation) {
			my $op_string = $self->_op_statement('$del',$op);
			$rstring .= $op_string . "\n";
			push(@$new_ops,$op_string);			
		}
		$self->{"_operations_"} = \(@$ops,@$new_ops);
		return $rstring;
	}
	return undef;
	
}


sub _resolve {
	my $self = shift;
	
}

sub discovery {
	my $self = shift;
	my $xri_authority = "http://xri2xdi.net";
	my $logger = get_logger();
	my ($xdi) = @_;
	my $disc = $self->_op_statement('$get',$xdi);
	my $pre = $self->{"_preamble_"};
	my $copy = clone($pre);
	push(@$copy,$disc);
	my $msg = join("\n",@$copy);	
	$logger->debug("Discover: $disc");
	my $result = _post($xri_authority,$msg);
	if ($result) {
		my $hash = decode($result);
		return $hash;
	}
	return undef;
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
sub get_xdi_inumber {
	my ($graph,$iname) = @_;
	my $logger = get_logger();
	# URI xri for XDI endpoint defined https://wiki.oasis-open.org/xdi/XdiDiscovery
	my $xri = '$is';
	my $match = [$iname,$xri,undef];
	my $tuple = pick_xdi_tuple($graph,$match);
	if (defined $tuple) {
		$logger->debug("get inumber: ", sub {Dumper($tuple)});
		return $tuple->[2];
	}
	return undef;
}


sub get_xdi_uri {
	my ($graph) = @_;
	my $logger = get_logger();
	# URI xri for XDI endpoint defined https://wiki.oasis-open.org/xdi/XdiDiscovery
	my $xri = '$xdi$*($v)$!1';
	my $match = [undef,undef,$xri];
	my $tuple = pick_xdi_tuple($graph,$match);
	if (defined $tuple) {
		my $subject = $tuple->[0];
		$match = [$subject,'!',undef];
		my $uri = pick_xdi_tuple($graph,$match);
		if (defined $uri) {
			return $uri->[2];
		}
	}
	return undef;
}

sub decode {
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




sub _get_server_uri {
	my $self = shift;
	# TODO: process to take the value from from_graph and get the URI
	my $graph = $self->discovery($self->{'to_graph'});
	my $uri = get_xdi_uri($graph) || $self->{"_server_"};
	return $uri;	
}

sub _pick_literal {
	my ($literal_key,$graph) = @_;
	if (defined $graph) {
		# TODO: Picking a value from XDI graph
	} else {
		return undef;
	}
}

sub _get_message_id {
	my $self = shift;
	if ($USE_LOCAL_MESSAGE) {		
		$self->{'_count_'} = 0 unless (defined $self->{'_count_'});
		my $num = $self->{'_count_'};
		return ('$(!' . $self->id . '-' . $num .')');		
	} else {
		return '($!)';
	}
}


sub _local_requestor {
	my $self = shift;
	my ($msg_id) = @_;
	my $string = "(" . $self->from_graph . ')/$add/' . $self->from . '$($msg)'. $msg_id;
	return $string;
}

sub _target_graph {
	my $self = shift;
	my ($msg_id) = @_;
	my $string = $self->from_graph . '$($msg)' . $msg_id . '/$is()/(' . $self->to_graph . ')';
	return $string;
}

sub _timestamp {
	my $self = shift;
	my ($msg_id) = @_;
	my $now = DateTime->now;
	my $f = DateTime::Format::RFC3339->new();
	my $ts = $f->format_datetime($now);
	my $string = $self->from_graph . '$($msg)' . $msg_id . '$d/!/(data:,' . $ts . ')';
	return $string;
}

sub _link_contract {
	my $self = shift;
	my ($msg_id) = @_;
	my $string = $self->from_graph . '$($msg)' . $msg_id . '/$do/' . $self->link_contract . '$do';
	return $string;
}
sub _op_statement {
	my $self = shift;
	my ($op,$target) = @_;
	my $msg_id = $self->_get_message_id;
	my $string = $self->from_graph . '$($msg)' . $msg_id . '$do/' . $op . '/' . $target;
	return $string;
	
}


=pod
Until a discovery process is in place, the uri will be set manually
=cut
sub set_server_url {
	my $self = shift;
	my ($uri) = @_;
	$self->{"_server_"} = $uri;
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
