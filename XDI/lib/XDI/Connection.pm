package XDI::Connection;  # must live in Some/Module.pm

use lib qw(..);
use strict;

use Carp qw(
	carp
	croak
	cluck
);
use Log::Log4perl qw(get_logger :levels);
use Data::Dumper;
use Storable qw(dclone);
use Scalar::Util;
use HTTP::Request;
use LWP::UserAgent;

use XDI qw(s_debug);
use XDI::Message;

require Exporter;
use vars       qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

# set the version for version checking
$VERSION     = 0.01;

@ISA         = qw(Exporter);
@EXPORT      = qw(&func1 &func2 &func4);
%EXPORT_TAGS = ( );   

@EXPORT_OK   = qw($Var1 %Hashit &func3);

use vars qw($Var1 %Hashit);
# non-exported package globals go here
use vars      qw();

# file-private lexicals go here
my %fields = (
	target => undef,
	secret => undef,
	resolve => 1,
	server => undef
);

our $AUTOLOAD;
our $USE_LOCAL_MESSAGE = 1;
our $XRI_AUTHORITY = "http://xri2xdi.net";

sub new {
	my $class  = shift;
	my $xdi = shift;
	my $self = {%fields,};
	bless($self,$class);
	if (ref $xdi ne 'XDI') {		
		my ($p,$s) = XDI->s_debug();
		carp "$p requires object 'XDI' in $s";
		return undef;
	} else {
		$self->{'__xdi__'} = $xdi;
	}
	my ($var_hash) = @_;
	if (defined $var_hash  ) {
		if (ref $var_hash eq "HASH"){
			foreach my $varkey (keys %{$var_hash}) {
				if (exists $self->{$varkey}) {
					$self->{$varkey} = $var_hash->{$varkey};
				}
			}
		} else {
		croak "Initialization failed: parameters not passed as hash reference or iname string";
		}
	} 
	$self->{'server'} = lookup($self->target)->[2] unless (defined $self->{'server'});
	
	return $self;	
}


sub post {
	my $self = shift;
	my ($msg,$test) = @_;
	my $body;
	if (ref $msg eq 'XDI::Message') {
		$body = $msg->to_string();
	} elsif(ref $msg eq '') {
		$body = $msg;
	} else {
		return undef;
	}	
}

sub lookup {
	my $obj = shift;
	my $xdi;
	if (ref $obj eq "XDI::Connection") {
		$xdi = shift;
	} else {
		$xdi = $obj;
	}
	if (XDI::is_inumber($xdi)) {
		return inumber_lookup($xdi);
	} else {
		return iname_lookup($xdi);
	}
}

sub iname_lookup {
	my $obj = shift;
	my $iname;
	if (ref $obj eq "XDI::Connection") {
		$iname = shift;
	} else {
		$iname = $obj;
	}
	my $struct = xdi_lookup($iname);
	my $temp = XDI::pick_xdi_tuple($struct,[$iname,'$is']);
	my $inumber = $temp->[2];
	my $subject = '('. $inumber . ')$!($uri)';
	$temp = XDI::pick_xdi_tuple($struct,[$subject,'!']);
	my $url = $temp->[2];
	return [$iname,$inumber,$url];
	
}

sub inumber_lookup {
	my $obj = shift;
	my $inumber;
	if (ref $obj eq "XDI::Connection") {
		$inumber = shift;
	} else {
		$inumber = $obj;
	}
	my $iname = undef;
	my $struct = xdi_lookup($inumber);
	print Dumper($struct);
	my $subject = '('. $inumber . ')$!($uri)';
	my $temp = XDI::pick_xdi_tuple($struct,[$subject,'!']);
	my $url = $temp->[2];
	return [$iname,$inumber,$url];
	
}


sub xdi_lookup {
	my $obj = shift;
	my $iname;
	if (ref $obj eq "XDI::Connection") {
		$iname = shift;
	} else {
		$iname = $obj;
	}
	my $authority = $XRI_AUTHORITY;
	# Populate the msg with dummy XDI data
	my $rstruct = {
		"from_graph" => '=1111',
		"from" => '=1111',
		"target" => $iname,
		"link_contract" => '()',				
	};
	my $msg = XDI::Message->new($rstruct);
	$msg->get($iname);
	print $msg->to_string, "\n";
	my $resp = _post($authority,$msg->to_string);
	return XDI::_decode($resp);
}



sub _post {
	my ($server, $body) = @_;
	my $logger = get_logger();
	my $request = HTTP::Request->new( 'POST', $server);
	my $ua = new LWP::UserAgent;
	$request->content($body);
	my $response = $ua->request($request);
	my $code = $response->code;
	my $content = $response->content;
	return $content;	
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

END { }       # module clean-up code here (global destructor)

1;


