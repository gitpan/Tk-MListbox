#!/usr/bin/perl -w

# MListbox demonstration application.

# Author: Hans J. Helgesen, December 1999.
#
# Before March 2000:
#
# Please send comments, suggestions and error reports to 
# hans_helgesen@hotmail.com.
#
# From March 2000: hans.helgesen@novit.no
#
use Tk;
use Tk::MListbox;
use Tk::Pane;
use DBI;

my $intro = <<EOT;
This is a very simple DBI application that demonstrates the use of MListbox.

* To execute a query, type the query in the query window and click "GO".
* To resize any of the columns, drag the vertical bar to the RIGHT of the column.
* To move any of the columns, drag the column header left or right.
* To sort the table, click on any of the column headers. A new click will reverse the sort order.
EOT

# Check argument.
if (@ARGV != 3) {
    print STDERR "Usage: $0 source userid password\n";
    print STDERR "Example: $0 dbi:Oracle:oradb peter secretpwd\n";
    exit 1;
}

# Connect to the database.
my $dbh = DBI->connect(@ARGV) or die "Can't connect: $DBI::errstr\n";


# Create Tk window...    
my $mw = new MainWindow;
$mw->title ("SQL $ARGV[1]\@$ARGV[0]");

$mw->Label(-text=>$intro,-justify=>'left')->pack(-anchor=>'w');

my $f=$mw->Frame->pack(-fill=>'x',-anchor=>'w');
my $text = $f->Scrolled('Text',-scrollbars=>'osoe',
			-width=>80,-height=>5)->pack(-side=>'left',
						      -expand=>1,
						      -fill=>'both');
$text->insert('end','select * from edi_order where rownum<1000');
$f=$f->Frame->pack(-side=>'left');

$f->Button(-text=>'Go',
	   -command=>sub {
	       $mw->Busy;
	       execSQL();
	       $mw->Unbusy;
	   })->pack;

$f->Button(-text=>'Clear',
	   -command=>sub {
	       $text->delete('0.0','end');
	   })->pack;

$f->Button(-text=>'Exit',
	   -command=>sub {
	       $dbh->disconnect;
	       exit;
	   })->pack;

# Put the MListbox in a Pane, since the MListbox don't support horizontal
# scrolling by itself.
#

my $ml = $mw->Scrolled('MListbox',
		      -scrollbars => 'osoe')
    ->pack(-expand=>1,-fill=>'both');

MainLoop;

#--------------------------------------------------------------------
#
sub execSQL
{
    # Get the query from the text widget.
    my $sql = $text->get('0.0','end');
    
    my $sth = $dbh->prepare($sql);
    unless (defined $sth) {
	$text->insert('end', "\nprepare() failed: $DBI::errstr\n");
	return;
    }
    unless ($sth->execute) {
	$text->insert('end', "\nexecute() failed: $DBI::errstr\n");
	return;
    }
    
    # Query OK, delete all old columns in $ml.
    #
    $ml->columnDelete(0,'end');
    my $headings_defined=0;
    while (my $hashref = $sth->fetchrow_hashref) {
	unless ($headings_defined) {
	    foreach (sort keys %$hashref) {
		$ml->columnInsert('end',-text=>$_);
	    }
	    $headings_defined=1;
	}
	my @row=();
	foreach (sort keys %$hashref) {
	    push @row, $hashref->{$_};
	}
	$ml->insert('end', [@row]);
    }
}
    





