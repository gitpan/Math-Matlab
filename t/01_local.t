#!/usr/bin/perl -w

BEGIN {
	use lib qw ( t );
}
use strict;
use Test::More tests => 9;
# use Test::More qw(no_plan);
use Cwd qw( abs_path );

use vars qw( $MATLAB_CMD );
require "matlab.config";
$Math::Matlab::Local::CMD = $MATLAB_CMD;

require_ok('Math::Matlab::Local');

my $t = 'new';
my $matlab = Math::Matlab::Local->new;
isa_ok( $matlab, 'Math::Matlab::Local', $t );

my $code = <<ENDOFCODE;
x = 1:10;
y = x .^ 2;
fprintf('%d\\t%d\\n', [x; y]);
ENDOFCODE

my $expected = <<ENDOFRESULT;
1	1
2	4
3	9
4	16
5	25
6	36
7	49
8	64
9	81
10	100
ENDOFRESULT

$t = 'execute';
my $rv = $matlab->execute($code);
ok( $rv, $t );

$t = 'fetch_result';
my $got = $matlab->fetch_result	if $rv;
is( $got, $expected, $t );

print $matlab->err_msg	unless $rv;

$t = 'new( { root_mwd => ... } )';
$matlab = Math::Matlab::Local->new( {	root_mwd => abs_path('./t/mwd0'),
										cmd      => $Math::Matlab::Local::CMD	} );
ok( $matlab, $t );

$t = 'execute($code)';
$rv = $matlab->execute( "fprintf( '\%.1f\\n', foo(5));" );
ok( $rv, $t );

$t = 'fetch_result';
$got = $matlab->fetch_result	if $rv;
cmp_ok( $got, '==', 25, $t );

print $matlab->err_msg	unless $rv;

$t = 'execute($code, $rel_mwd)';
$matlab = Math::Matlab::Local->new( {	root_mwd => abs_path('./t'),
										cmd      => $Math::Matlab::Local::CMD	} );
$rv = $matlab->execute( "fprintf( '\%.1f\\n', foo(5));", 'mwd1' );
ok( $rv, $t );

$t = 'fetch_result';
$got = $matlab->fetch_result	if $rv;
cmp_ok( $got, '==', 26, $t );

print $matlab->err_msg	unless $rv;

1;

=pod

=head1 NAME

01_local.t - Tests for Math::Matlab::Local.

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 LIST OF TESTS

=head1 CHANGE HISTORY

=head1 COPYRIGHT

Copyright (c) 2002 PSERC. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

  Ray Zimmerman, <rz10@cornell.edu>

=head1 SEE ALSO

 perl(1)

=cut
