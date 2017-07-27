#!/bin/perl
=head1 NAME

 rhelMpStat.pl

=head1 SYNOPSIS

 IntroscopeEPAgent.properties configuration

 introscope.epagent.plugins.stateless.names=MPSTAT
 introscope.epagent.stateless.MPSTAT.command=perl <epa_home>/epaplugins/rhel/rhelMpStat.pl
 introscope.epagent.stateless.BINDINGS.delayInSeconds=15

=head1 DESCRIPTION

 Pulls multi-processor statistics

 To see help information:

 perl <epa_home>/epaplugins/rhel/rhelMpStat.pl --help

 or run with no commandline arguments.

 To test against sample output, use the DEBUG flag:

 perl <epa_home>/epaplugins/rhel/rhelMpStat.pl --debug

=head1 CAVEATS

 NONE

=head1 AUTHOR

 Hiko Davis, Principal Services Consultant, CA Technologies

=head1 COPYRIGHT

 Copyright (c) 2016

 This plug-in is provided AS-IS, with no warranties, so please test thoroughly!

=cut

use FindBin;
use lib ("$FindBin::Bin", "$FindBin::Bin/lib/perl", "$FindBin::Bin/../lib/perl");
use Wily::PrintMetric;

use Getopt::Long;
use strict;

=head2 SUBROUTINES

=cut

=head3 USAGE

 Prints help information for this program

=cut
sub usage {
    print "Unknown option: @_\n" if ( @_ );
    print "usage: $0 <epa_home>/epaplugins/rhel/rhelMpStat.pl[--help|-?] [--debug]\n\n";
    exit;
}

my ($help, $debug);
&usage if ( not GetOptions( 'help|?' => \$help,
                            'debug!' => \$debug,
                          )
            or defined $help );
    
my ($mpstatCommand, @mpstatResults);

if ($debug) {
    # use here-docs for command results
    @mpstatResults = <<"SAMPLE" =~ m/(^.*\n)/mg;
Linux 2.6.32-642.1.1.el6.x86_64 (rhel-apm10.test.vmware)    08/05/2016  _x86_64_    (2 CPU)

07:22:58 PM  CPU    %usr   %nice    %sys %iowait    %irq   %soft  %steal  %guest   %idle
07:22:58 PM  all    0.57    0.02    0.38    0.11    0.00    0.02    0.00    0.00   98.90
07:22:58 PM    0    0.59    0.02    0.37    0.10    0.00    0.01    0.00    0.00   98.92
07:22:58 PM    1    0.55    0.02    0.39    0.13    0.00    0.03    0.00    0.00   98.89
SAMPLE
} else {
    # gather stats from server
    $mpstatCommand = 'mpstat -P ALL';
    @mpstatResults = `$mpstatCommand`;
}


# Get rid of the header lines for each command
@mpstatResults = @mpstatResults[3..$#mpstatResults];


# parse the mpstat results and report the
# relevant data using metrics
foreach my $isline (@mpstatResults) {
	chomp $isline; # remove trailing new line
	# remove leading spaces
    $isline =~ s/^\s+//;
	my @cpuStats = split(/\s+/, $isline);
	my $cpu = $cpuStats[2];
	# prepend a zero to CPUs 1-9
	if ( int($cpu) >= 1 && int($cpu) <= 9 ) {
	    $cpu = "0". $cpu;
	}
	
	# report mpstats
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu_" . $cpu,
                                    name        => '%usr',
                                    value       => sprintf("%.0f", $cpuStats[3]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu_" . $cpu,
                                    name        => '%nice',
                                    value       => sprintf("%.0f", $cpuStats[4]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu_" . $cpu,
                                    name        => '%sys',
                                    value       => sprintf("%.0f", $cpuStats[5]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu_" . $cpu,
                                    name        => '%iowait',
                                    value       => sprintf("%.0f", $cpuStats[6]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu_" . $cpu,
                                    name        => '%irq',
                                    value       => sprintf("%.0f", $cpuStats[7]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu_" . $cpu,
                                    name        => '%soft',
                                    value       => sprintf("%.0f", $cpuStats[8]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu_" . $cpu,
                                    name        => '%steal',
                                    value       => sprintf("%.0f",$cpuStats[9]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu_" . $cpu,
                                    name        => '%guest',
                                    value       => sprintf("%.0f", $cpuStats[10]),
                                  );
	Wily::PrintMetric::printMetric( type        => 'IntCounter',
                                    resource    => 'MPSTAT',
                                    subresource => "cpu_" . $cpu,
                                    name        => '%idle',
                                    value       => sprintf("%.0f", $cpuStats[11]),
                                  );
}
