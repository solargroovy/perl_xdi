#!/usr/bin/perl -w

use lib qw(
	./
	../
);

use Test::More;
use Test::Deep;
use Data::Dumper;

use HTTP::XDI;

use Log::Log4perl qw(get_logger :levels);
Log::Log4perl->easy_init($INFO);
Log::Log4perl->easy_init($DEBUG);


# defaults
# "@kynetx/$is" : [ "@!3436.F6A6.3644.4D74" ]
my $test_count = 0;
my $logger = get_logger();

my $to_graph = '@kynetx';
my $from_graph = '@kynetx';
my $from = '=mark';
my $lc = '@kynetx';
#my $test_server = "http://10.0.1.146:8080/xdi/bdb-graph";
my $test_server = "http://10.0.1.194:8080/xdi/mem-graph";

my $xdi1 = new HTTP::XDI;

$xdi1->to_graph($to_graph);
cmp_deeply($xdi1->to_graph,$to_graph,"Set graph target");
$test_count++;

$xdi1->from_graph($from_graph);
cmp_deeply($xdi1->from_graph,$from_graph,"Set graph authority");
$test_count++;

$xdi1->from($from);
cmp_deeply($xdi1->from,$from,"Set graph requestor");
$test_count++;

$xdi1->link_contract($lc);
cmp_deeply($xdi1->link_contract,$lc,"Set link contract");
$test_count++;
cmp_deeply($xdi1->validate,1,"All data in place for call");
$test_count++;

my $hash = {
	from_graph => $from_graph,
	from => $from,
	to_graph => $to_graph,
	link_contract => $lc	
	
}; 

my $xdi2 = new HTTP::XDI($hash);
cmp_deeply($xdi2->validate,1,"Test hash constructor");
$test_count++;

my $operation = '@kynetx';
$xdi2->connect;
my $result = $xdi2->get($operation);

$logger->debug("Result: ", sub {Dumper($result)});
$xdi2->set_server_url ($test_server);
$result = $xdi2->post;
$logger->debug("\@Kynetx get Result: ", sub {Dumper($result)});

#die;

my $xdi_del = new HTTP::XDI($hash);
$xdi_del->connect;
$xdi_del->set_server_url ($test_server);
$xdi_del->del('()');
$result = $xdi_del->post;
$logger->debug("Delete Result: ", sub {Dumper($result)});


$xdi1->connect;
$xdi1->set_server_url($test_server);
#$xdi1->del('()');
$xdi1->add('()/()/=animesh');
$xdi1->add('()/()/=!1111');
$xdi1->add('=animesh/$is/=!1111');


$xdi1->add('()/()/=markus');
$xdi1->add('()/()/@kynetx');
$xdi1->add('()/()/@!3436.F6A6.3644.4D74');
$xdi1->add('()/()/(@!3436.F6A6.3644.4D74)');
$xdi1->add('(@!3436.F6A6.3644.4D74)/$is/()');
$xdi1->add('@kynetx/$is/@!3436.F6A6.3644.4D74');
#goto ENDY;
#die;

#
$xdi1->add('()/()/=!2222');
$xdi1->add('=markus/$is/=!2222');
#
$xdi1->add('()/()/(http://amazon.com)');

$xdi1->add('=!1111/()/$*($uri)');

$xdi1->add('=!1111/+friend/=!2222');
$xdi1->add('=!1111/+supplier/(http://amazon.com)');
$xdi1->add('=!1111/()/$!(+firstname)');
$xdi1->add('=!1111/()/$!(+lastname)');
$xdi1->add('=!1111/()/$*(+tel)');
$xdi1->add('=!1111/()/$*(+email)');
$xdi1->add('=!1111/()/$*(+profession)');
$xdi1->add('=!1111/()/$*(+interest)');
$xdi1->add('=!1111/()/$!(+dateofbirth)');
$xdi1->add('=!1111/()/$!(+gender)');
$xdi1->add('=!1111/()/+calendar');
$xdi1->add('=!1111/()/+dropbox');
$xdi1->add('=!1111/()/+wallet');
$xdi1->add('=!1111/()/$(+address)');


$xdi1->add('=!1111$!(+firstname)/!/(data:,Animesh)');
$xdi1->add('=!1111$!(+lastname)/!/(data:,Chowdhury)');
$xdi1->add('=!1111$*(+tel)/()/($1)');
$xdi1->add('=!1111$*(+tel)/()/($2)');
$xdi1->add('=!1111$*(+tel)/()/($3)');
$xdi1->add('=!1111$*(+tel)($1)/!/(data:,+1.206.555.1111)');
$xdi1->add('=!1111$*(+tel)($2)/!/(data:,+1.206.555.2222)');
$xdi1->add('=!1111$*(+tel)($3)/!/(data:,+1.206.555.3333)');
$xdi1->add('=!1111$*(+tel)/+personal/=!1111$*(+tel)($1)');
$xdi1->add('=!1111$*(+tel)/+home/=!1111$*(+tel)($2)');
$xdi1->add('=!1111$*(+tel)/+work/=!1111$*(+tel)($3)');

$xdi1->add('=!1111$*(+email)/()/$!1');
$xdi1->add('=!1111$*(+email)/()/$!2');
$xdi1->add('=!1111$*(+email)$!1/!/(data:,animesh.chowdhury@gmail.com)');
$xdi1->add('=!1111$*(+email)$!2/!/(data:,animesh.chowdhury@neustar.biz)');
$xdi1->add('=!1111$*(+email)/+personal/=!1111$*(+email)$!1');
$xdi1->add('=!1111$*(+email)/+work/=!1111$*(+email)$!2');
$xdi1->add('=!1111$*(+profession)/()/$!1');
$xdi1->add('=!1111$*(+profession)/()/$!2');
$xdi1->add('=!1111$*(+profession)$!1/!/(data:,SoftwareDeveloper)');
$xdi1->add('=!1111$*(+profession)$!2/!/(data:,StandUpComedian)');
$xdi1->add('=!1111$*(+interest)/()/$!1');
$xdi1->add('=!1111$*(+interest)/()/$!2');
$xdi1->add('=!1111$*(+interest)$!1/!/(data:,Online%20Identity%20and%20Privacy)');
$xdi1->add('=!1111$*(+interest)$!2/!/(data:,Silent%20Movies)');
$xdi1->add('=!1111$!(+dateofbirth)/!/(data:,1993-06-26T14:35:00Z)');

$xdi1->add('=!1111$!(+gender)/!/(data:,male)');
$xdi1->add('=!1111+calendar/()/$(+event)');
$xdi1->add('=!1111+calendar$(+event)/()/$!1');
$xdi1->add('=!1111+calendar$(+event)/()/$!2');
$xdi1->add('=!1111+calendar$(+event)$!1/()/$!(+time)');
$xdi1->add('=!1111+calendar$(+event)$!1/()/$!(+location)');
$xdi1->add('=!1111+calendar$(+event)$!1/()/$!(+topic)');

$xdi1->add('=!1111+calendar$(+event)$!1$!(+time)/!/(data:,2012-06-27T14:35:00Z)');
$xdi1->add('=!1111+calendar$(+event)$!1$!(+location)/!/(data:,Washington%20DC)');
$xdi1->add('=!1111+calendar$(+event)$!1$!(+topic)/!/(data:,IIW)');

$xdi1->add('=!1111+calendar$(+event)$!2/()/$!(+time)');
$xdi1->add('=!1111+calendar$(+event)$!2/()/$!(+location)');
$xdi1->add('=!1111+calendar$(+event)$!2/()/$!(+topic)');

$xdi1->add('=!1111+calendar$(+event)$!2$!(+time)/!/(data:,2012-07-27T14:35:00Z)');
$xdi1->add('=!1111+calendar$(+event)$!2$!(+location)/!/(data:,Santa%20Clara%20CA)');
$xdi1->add('=!1111+calendar$(+event)$!2$!(+topic)/!/(data:,Do%20Not%20Track%20Workshop)');


$xdi1->add('=!1111+dropbox/()/$(+file)');
$xdi1->add('=!1111+dropbox$(+file)/()/$!1');
$xdi1->add('=!1111+dropbox$(+file)/()/$!2');
$xdi1->add('=!1111+dropbox$(+file)$!1/()/$!(+filename)');
$xdi1->add('=!1111+dropbox$(+file)$!1/()/$!(+mimetype)');
$xdi1->add('=!1111+dropbox$(+file)$!1/()/$!(+binarycontent)');

$xdi1->add('=!1111$(+address)/()/$!1');
$xdi1->add('=!1111$(+address)/()/$!2');

$xdi1->add('=!1111$(+address)$!1/()/$*(+street)');
$xdi1->add('=!1111$(+address)$!1/()/$!(+city)');
$xdi1->add('=!1111$(+address)$!1/()/$!(+state)');
$xdi1->add('=!1111$(+address)$!1/()/$!(+postal.code)');
$xdi1->add('=!1111$(+address)$!1/()/$!(+country)');

$xdi1->add('=!1111$(+address)$!1$*(+street)$!1/!/(data:,123%20home%20address%20line1)');
$xdi1->add('=!1111$(+address)$!1$*(+street)$!2/!/(data:,123%20home%20address%20line2)');
$xdi1->add('=!1111$(+address)$!1$!(+city)/!/(data:,Sterling)');
$xdi1->add('=!1111$(+address)$!1$!(+state)/!/(data:,VA)');
$xdi1->add('=!1111$(+address)$!1$!(+postal.code)/!/(data:,20166)');
$xdi1->add('=!1111$(+address)$!1$!(+country)/!/(data:,US)');

$xdi1->add('=!1111$(+address)$!2/()/$*(+street)');
$xdi1->add('=!1111$(+address)$!2/()/$!(+city)');
$xdi1->add('=!1111$(+address)$!2/()/$!(+state)');
$xdi1->add('=!1111$(+address)$!2/()/$!(+postal.code)');
$xdi1->add('=!1111$(+address)$!2/()/$!(+country)');

$xdi1->add('=!1111$(+address)$!2$*(+street)$!1/!/(data:,123%20home%20address%20in%20INDIA%20line1)');
$xdi1->add('=!1111$(+address)$!2$*(+street)$!2/!/(data:,123%20home%20address%20in%20INDIA%20line2)');
$xdi1->add('=!1111$(+address)$!2$!(+city)/!/(data:,Calcutta)');
$xdi1->add('=!1111$(+address)$!2$!(+state)/!/(data:,WB)');
$xdi1->add('=!1111$(+address)$!2$!(+postal.code)/!/(data:,712410)');
$xdi1->add('=!1111$(+address)$!2$!(+country)/!/(data:,IN)');

$xdi1->add('=!1111+wallet/()/$(+creditcard)');
$xdi1->add('=!1111+wallet$(+creditcard)/()/$!1');
$xdi1->add('=!1111+wallet$(+creditcard)/()/$!2');
$xdi1->add('=!1111+wallet$(+creditcard)$!1/()/$!(+number)');
$xdi1->add('=!1111+wallet$(+creditcard)$!1/()/$!(+expirationdate)');
$xdi1->add('=!1111+wallet$(+creditcard)$!1/()/$!(+name)');
$xdi1->add('=!1111+wallet$(+creditcard)$!1/+billingaddress/=!1111$(+address)$!1');
$xdi1->add('=!1111+wallet$(+creditcard)$!2/()/$!(+number)');
$xdi1->add('=!1111+wallet$(+creditcard)$!2/()/$!(+expirationdate)');
$xdi1->add('=!1111+wallet$(+creditcard)$!2/()/$!(+name)');
$xdi1->add('=!1111+wallet$(+creditcard)$!2/+billingaddress/=!1111$(+address)$!1');

$xdi1->add('=!1111$*($uri)$!1/!/(data:,http://www.facebook.com/)');
$xdi1->add('=!1111$*($uri)$!2/!/(data:,http://www.twitter.com/)');

ENDY:
#$xdi1->get('()');
$result = $xdi1->post;
$logger->debug("Adds: ", sub {Dumper($result)});

my $xdin = new HTTP::XDI($hash);

$operation = '@kynetx';
$xdin->connect;
$result = $xdin->get($operation);

$logger->debug("Result: ", sub {Dumper($result)});
$xdin->set_server_url ($test_server);
$result = $xdin->post;
$logger->debug("$operation get Result: ", sub {Dumper($result)});


done_testing($test_count);