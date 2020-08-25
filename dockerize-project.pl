#!/usr/bin/perl -w 

=head2

	DESCRIPTION:

		This runs the dockerfile build process to make a container image.
		Run this script in the actual project directory.

=cut

use strict;
use Getopt::Long;
use Data::Dumper;
use File::Slurp qw(write_file);

{
	my %args = (
		app_name => '',
		no_start => '',
		mode     => '',
		port     => ''
	);

	GetOptions(
		"app-name=s" => \$args{app_name},
		"nostart"    => \$args{no_start},
		"mode=s"     => \$args{mode},
		"port=i"     => \$args{port}
	);

	if ( $args{app_name} ) {
		my $result = init( %args );
		die "$result->{error} $!\n" if $result->{error};
	} else { 
		&use;
	}
};

sub use {
	die "
	- Create a docker image and start the container running a pm2 react node.
	
	Usage:
	
		$0 -option <value>
	
	Options:
	
		-app-name [REQUIRED] String.  Directory path of the project you wish to dockerize.
		-nostart  [Optional] Flag.    Don't run the container after the build.
		-mode     [Optional] String.  Defaults to production.
		-port     [Optional] Int.     Defaults to 5000.
			
	Examples: 
	
		1) $0 -app-name appdir -nostart
		2) $0 -app-name appdir
	$!\n";
}

# The mode can be prod or dev.
sub init {

	my ( %args ) = @_;

	my $mode     = $args{mode} || 'production';
	my $port     = $args{port} || 5000;
	my $no_start = $args{no_start};
	my $app_name = $args{app_name};

	my $result = {};

	if ( -d $app_name ) {

		my $has_files = check_project_files( app_name => $app_name );
		
		if ( $has_files ) {
		
			my $has_docker = `which docker`;
			chomp $has_docker;
		
			if ( $has_docker ) {
		
				# Create the docker file.
				make_dockerfile( app_name => $app_name );
		
				# Build the dockerfile.
				if ( -f 'dockerfile' ) {
					run_docker_build( mode => $mode, port => $port );
					run_docker( port => $port ) if !$no_start;
				} else {
					$result->{error} = 'Could not create dockerfile';
				}
		
			} else { 
				$result->{error} = "Missing docker runtime";
			}
		
		} else {
			$result->{error}  = "Missing files not a valid react pm2 project.\n";
			$result->{error} .= "git clone https://github.com/blunawork/react-production-setup.git and run create-react-node-pm2.pl";
		}

	} else {
		$result->{error} = "Could not find $app_name";
	}

	return $result;
}

# Look at the cwd to make sure there is a node-server and react-app.
sub check_project_files {

	my ( %args ) = @_;

	my $app_name = $args{app_name};

	my $is_ok = 0;

	if ( -f "$app_name/package.json" && -f "$app_name/ecosystem.config.js" ) {
		$is_ok = 1;
	}

	return $is_ok;
}

# Run the dockerfile build.
sub run_docker_build {

	my ( %args ) = @_;

	my $mode = $args{mode};
	my $port = $args{port};

	system( "sudo docker build -t react-frontend . --build-arg value=$mode --build-arg exposeportvalue=$port" );
}

# Generate a dockerfile for the build.
# Copy the app_name project to the docker image.
sub make_dockerfile {

	my ( %args ) = @_;

	my $app_name = $args{app_name};

	my $dockerfile = qq~FROM node:12
COPY $app_name /opt/app
WORKDIR /opt/app
RUN npm run build
RUN npm install serve -g
RUN npm install pm2 -g
ARG value
ENV envValue=\$value
ARG exposeportvalue
ENV envexposeport=\$exposeportvalue
EXPOSE \$envexposeport
CMD ["sh", "-c", "pm2-runtime start ecosystem.config.js --node-args=--require dotenv/config --env \${envValue}"]
~;
	write_file( 'dockerfile', $dockerfile );
}

# Execute exposing port.
sub run_docker {
	my ( %args ) = @_;

	my $port = $args{port};
	system( "sudo docker run -p $port:$port --name react-frontend -d react-frontend:latest" );
}
