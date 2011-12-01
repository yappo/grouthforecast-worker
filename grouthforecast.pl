#!/usr/bin/env perl
use strict;
use warnings;
use strict;
use File::Spec;
use File::Basename;
use LWP::UserAgent;
use Path::Class;

my $script_dir = shift @ARGV;

# GrowthForecast の /api の URL
my $growthforecast_endpoint = 'http://example.com/api';

# グラフをどのサービスに属するかを example の変わりに入れてね
my $service_name = 'example';

# 必要に応じて以下を書いてね
my $MYSQL_BATHCH_HOST     = '';
my $MYSQL_BATHCH_USER     = '';
my $MYSQL_BATHCH_PASSWORD = '';

my $ua = LWP::UserAgent->new;

sub post {
    my($section, $name, $number) = @_;
    my $res = $ua->post("$growthforecast_endpoint/$service_name/$section/$name", {
        number => $number,
    });
}

for my $section (dir($script_dir)->children) {
    my($section_name) = $section =~ m{/([^/]+)$};
    for my $graph ($section->children) {
        my($graph_name) = $graph =~ m{/([^/]+)$};
        next unless -x $graph;
        if (my($base_name) = $graph_name =~ /^bulk_(.+)$/) {
            my $ret = `MYSQL_BATHCH_HOST=$MYSQL_BATHCH_HOST MYSQL_BATHCH_USER=$MYSQL_BATHCH_USER MYSQL_BATHCH_PASSWORD=$MYSQL_BATHCH_PASSWORD $graph`;
            for my $line (split "\n", $ret) {
                next unless $line;
                my($sub_name, $number) = split "\t", $line;
                next unless $sub_name && defined $number && $number =~ /^[0-9]+$/;
                post($section_name, "${base_name}_$sub_name", $number);
            }
        } else {
            my $number = `MYSQL_BATHCH_HOST=$MYSQL_BATHCH_HOST MYSQL_BATHCH_USER=$MYSQL_BATHCH_USER MYSQL_BATHCH_PASSWORD=$MYSQL_BATHCH_PASSWORD $graph`;
            chomp $number;
            post($section_name, $graph_name, $number);
        }
    }
}
