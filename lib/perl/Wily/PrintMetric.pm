########################################################################
# Introscope EPAgent Print Metric Perl Library
#                                                                      
# CA Wily Introscope(R) Version 9.1 Release 9.1.1.0
# Copyright (c) 2012 CA. All Rights Reserved.
# Introscope(R) is a registered trademark of CA.
#
########################################################################
# PrintMetric Module
########################################################################

package Wily::PrintMetric;

use strict;

# import modules
#
use FindBin;
use lib ("$FindBin::Bin", "$FindBin::Bin/../lib/perl");
use Carp;

# Force auto-flush on STDOUT *and* STDERR because default flush behavior
# on file handles when talking to a pipe differs from console ouput
#
my $oldfh = select(STDOUT); $| = 1; select(STDERR); $| = 1; select($oldfh);

# this prints a metric in xml format based on the
# following arguments:
# 1) the metric type
# 2) the metric name
# 3) the metric value
#
# in the future we can modify this to take a configurable parameter
# that determines the form in which we print the data (xml, raw data, etc)

sub printMetric {

  my %args;
  my ($metricName, $metricValue, $metricType, 
          $resource, $subresource) = ();
  my $death;
 
  my $numArgs = scalar(@_);

  if ($numArgs == 3) { # backwards-compat, support 3 args

    ($metricType, $metricName, $metricValue) = @_;

  } else { # check for hash for named params if at least 3

    %args = @_;

    # mandatory
    #
    $metricType  = $args{type};
    $metricName  = $args{name};
    $metricValue = $args{value};

    croak "printMetric called with incorrect arguments (" .
          "'type', 'name', and 'value' are mandatory)" 
			if ( $metricType eq '' || 
				 $metricName eq '' || 
				 $metricValue eq ''  );

    # optional
    #
    $resource    = $args{resource};
    $subresource = $args{subresource};

	# check name for reserved chars
	#
    $metricName  =~ tr/[:|]/[_^]/; # colons, pipes are reserved 
    $resource    =~ tr/[:]/[_]/;   # colons reserved
    $subresource =~ tr/[:]/[_]/;   # colons reserved

    if ($resource || $subresource) {
        $metricName = "$resource|$subresource:$metricName";
        $metricName =~ s/\|:/:/g;   # subresource empty
        $metricName =~ s/^\|:?//g;  # resource empty, maybe subresource
    }

    # NOTE: colons & pipes allowed in String values...
	# check value for reserved chars
    # $metricValue =~ tr/[:|]/[_^]/; 

	# trim spaces
	#
    $metricName  =~ s/^\s*(.*)\s*$/$1/;
    $metricType  =~ s/^\s*(.*)\s*$/$1/;
    $metricValue =~ s/^\s*(.*)\s*$/$1/;

	# encode to be xml-safe
	$metricName  = encode_entities($metricName);
	$metricValue = encode_entities($metricValue);

  }

  print STDOUT <<EOF;
<metric type="$metricType" name="$metricName" value="$metricValue" />
EOF

}


####################################################
#
# Copy/modification of Entities.pm to work around 
# some Perl installation issues:
# 1) only kept SGML reserved chars (no LATIN chars)
# 2) made regex match in encode_entities not use
#    wide-open char ranges (non-portable)
#
####################################################

my %char2entity;

# 2002 11 14 jenko NOTE: the entity2char hash has been pruned
#
my %entity2char = (
 # Some normal chars that have special meaning in SGML context
 'amp'   => '&',  # ampersand 
 'gt'    => '>',  # greater than
 'lt'    => '<',  # less than
 'quot'  => '"',  # double quote
 'apos'  => "'",  # single quote
);


# Make the oposite mapping
while (my($entity, $char) = each(%entity2char)) {
    $char2entity{$char} = "&$entity;";
}
delete $char2entity{"'"};  # only one-way decoding

# 2002 11 14 jenko NOTE: this util regex match is
# generated on the fly. The Fill-in loop has been
# removed.

# Make a regex to match all reserved chars
# Do this after the delete of the single-quote above!
my $reserved_chars = join('',(keys %char2entity)); 
my $reserved_regex = qr/[$reserved_chars]/;

my %subst;  # compiled encoding regexps

sub decode_entities
{
    my $array;
    if (defined wantarray) {
        $array = [@_]; # copy
    } else {
        $array = \@_;  # modify in-place
    }
    my $c;
    for (@$array) {
        s/(&\#(\d+);?)/$2 < 256 ? chr($2) : $1/eg;
        s/(&\#[xX]([0-9a-fA-F]+);?)/$c = hex($2); $c < 256 ? chr($c) : $1/eg;
        s/(&(\w+);?)/$entity2char{$2} || $1/eg;
    }
    wantarray ? @$array : $array->[0];
}

sub encode_entities
{
    my $ref;
    if (defined wantarray) {
        my $x = $_[0];
        $ref = \$x;     # copy
    } else {
        $ref = \$_[0];  # modify in-place
    }
    if (defined $_[1]) {
        unless (exists $subst{$_[1]}) {
            # Because we can't compile regex we fake it with a cached sub
            $subst{$_[1]} =
              eval "sub {\$_[0] =~ s/([$_[1]])/\$char2entity{\$1} || num_entity(\$1)/ge; }";
            die $@ if $@;
        }
        &{$subst{$_[1]}}($$ref);
    } else {
        # 2002 11 14 jenko NOTE: this regex match has been changed
        # Encode control chars, high bit chars and '<', '&', '>', '"'
        $$ref =~ s/($reserved_regex)/$char2entity{$1} || num_entity($1)/ge;
    }
    $$ref;
}

sub num_entity {
    sprintf "&#x%X;", ord($_[0]);
}

# Set up aliases
*encode = \&encode_entities;
*decode = \&decode_entities;

####################################################
#
# END: Copy/modification of Entities.pm 
#
####################################################

1;

