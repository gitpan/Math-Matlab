package Math::Matlab::Local;

use strict;
use vars qw($VERSION $ROOT_MWD $CMD);

BEGIN {
	$VERSION = sprintf "%d.%03d", q$Revision: 1.6 $ =~ /: (\d+)\.(\d+)/;
}

use Math::Matlab;
use base qw( Math::Matlab );

use Cwd qw( getcwd abs_path );

##-----  assign defaults, unless already set externally  -----
$CMD		= 'matlab -nodisplay -nojvm'	unless defined $CMD;
$ROOT_MWD	= getcwd						unless defined $ROOT_MWD;

##-----  Public Class Methods  -----
sub new {
	my ($class, $href) = @_;
	my $self	= {
		cmd			=> defined($href->{cmd})		? $href->{cmd}		: $CMD,
		root_mwd	=> defined($href->{root_mwd}) 	? $href->{root_mwd}	: $ROOT_MWD,
		err_msg		=> '',
		result		=> ''
	};

	bless $self, $class;
}

##-----  Public Object Methods  -----
sub execute {
	my ($self, $code, $rel_mwd, $fn) = @_;
	my $success	= 1;
	my ($cwd, $cmd);
	
	## save current directory and change to Matlab working directory
	$cwd = getcwd	if $self->root_mwd or $rel_mwd;
	if ($self->root_mwd) {
		chdir $self->root_mwd	or die("Couldn't chdir to '@{[ $self->root_mwd ]}'");
	}
	if ($rel_mwd) {
		my $mwd = abs_path( $rel_mwd );
		chdir $mwd	or die("Couldn't chdir to '$mwd'");
	}
	
	## create input file
	$fn = $self->create_cmd_file($code, $fn);

	## set up command to fire off Matlab with the input file
	$cmd = $self->cmd . " < $fn";

	## run it
	$self->{'result'} = `$cmd`;

	## return true if everythings fine, set errormsg and return false otherwise
	if ($self->{'result'} =~ /Copyright (.+) MathWorks/) {
		unlink $fn;								## delete input file
	} else {
		$success = 0;
		$self->err_msg('`' . $cmd . '`' . ' in ' . getcwd . " returned:\n" . $self->{'result'});
	}

	## restore current working directory
	if ($cwd) {
		chdir $cwd	or die("Couldn't chdir to '$cwd'");
	}

	return $success;
}

sub create_cmd_file {
	my ($self, $code, $fn, $overwrite) = @_;
	my $success	= 1;
	my ($cmd);
	
	## create input file
	if (defined($fn)) {	## filename given
		$overwrite = 0	unless defined $overwrite;
		die("File '$fn' already exists")	if !$overwrite && -f $fn;
	} else {			## filename not given
		while (!defined($fn) or -f $fn) {		## generate random file name
			$fn = 'cmd' . (int rand 1000000000) . '.m';
		}
	}
	open(Matlab::IO, ">$fn") || die "Couldn't open '$fn'";
	print Matlab::IO	"fprintf('-----MATLAB-BEGIN-----\\n');\n" .
						$code . "\n" .
						"fprintf('------MATLAB-END------\\n');\n";
	close(Matlab::IO);

	return $fn;
}

sub cmd {		my $self = shift; return $self->_getset('cmd',		@_); }
sub root_mwd {	my $self = shift; return $self->_getset('root_mwd',	@_); }

1;
__END__

=head1 NAME

Math::Matlab::Local - Interface to a local Matlab process.

=head1 SYNOPSIS

  use Math::Matlab::Local;
  $matlab = Math::Matlab::Local->new({
      cmd      => '/usr/local/matlab -nodisplay -nojvm',
      root_mwd => '/path/to/matlab/working/directory/'
  });
  
  my $code = q/fprintf( 'Hello world!\n' );/;
  if ( $matlab->execute($code) ) {
      print $matlab->fetch_result;
  } else {
      print $matlab->err_msg;
  }

=head1 DESCRIPTION

Math::Matlab::Local implements an interface to a local Matlab
executeable. It takes a string containing Matlab code, saves it to a
file in a specified directory and invokes the Matlab executeable with
this file, capturing everything the Matlab program prints to STDOUT.

=head1 Attributes

=over 4

=item cmd

A string containing the command used to invoke the Matlab executeable.
The default is taken from the package variable $CMD, whose default value
is 'matlab -nodisplay -nojvm'

=item root_mwd

A string containing the absolute path to the root Matlab working
directory. All Matlab code is executed in directories which are
specified relative to this path. The default is taken from the package
variable $ROOT_MWD, whose default value is the current working
directory.

=back

=head1 METHODS

=head2 Public Class Methods

=over 4

=item new

 $matlab = Math::Matlab::Local->new;
 $matlab = Math::Matlab::Local->new( {
    cmd      => '/usr/local/matlab -nodisplay -nojvm',
    root_mwd => '/root/matlab/working/directory/'
 } )

Constructor: creates an object which can run Matlab programs and return
the output. Attributes 'cmd' and 'root_mwd' can be initialized via a
hashref argument to new(). Defaults for these values are taken from the
package variables $CMD and $ROOT_MWD, respectively.

=back

=head2 Public Object Methods

=over 4

=item execute

 $TorF = $matlab->execute($code)
 $TorF = $matlab->execute($code, $relative_mwd)
 $TorF = $matlab->execute($code, $relative_mwd, $filename)

Takes a string containing Matlab code, saves it to a command file in a
specified directory and invokes the Matlab executeable with this file as
input, capturing everything the Matlab program prints to STDOUT. The
optional second argument specifies the Matlab working directory relative
to the root Matlab working directory for the object. This is where the
command file will be created and Matlab invoked. The optional third
argument specifies the filename to use for the command file. The output
is stored in the object. Returns true if successful, false otherwise.

=item create_cmd_file

 $filename = $matlab->create_cmd_file($code)
 $filename = $matlab->create_cmd_file($code, $filename)
 $filename = $matlab->create_cmd_file($code, $filename, $overwrite)

Saves the given Matlab code to a new command file. If no filename is
given, it generates a random unique one. If the filename is given and a
file already exists with that name, it will throw an exception, unless
the third optional argument is true. In that case it will overwrite the
file. It returns the name of the file created.

=item cmd

 $cmd = $matlab->cmd
 $cmd = $matlab->cmd($cmd)

Get or set the command used to invoke Matlab.

=item root_mwd

 $root_mwd = $matlab->root_mwd
 $root_mwd = $matlab->root_mwd($root_mwd)

Get or set the root Matlab working directory.

=back

=head1 CHANGE HISTORY

=over 4

=item *

10/16/02 - (RZ) Created.

=back

=head1 COPYRIGHT

Copyright (c) 2002 PSERC. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

  Ray Zimmerman, <rz10@cornell.edu>

=head1 SEE ALSO

  perl(1), Math::Matlab

=cut
