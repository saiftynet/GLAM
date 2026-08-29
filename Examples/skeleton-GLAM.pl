#!/usr/bin/env perl
# GLAM    OpenGL variant
# Needs gl and glfw
# sudo apt install libopengl-perl
# sudo apt install libglfw3
# sudo apt install libglfw3-dev
# sudo cpanm OpenGL OpenGL::GLFW

use lib "../lib";
use strict;
use warnings;
use Time::HiRes qw(usleep);
use GLAM::OpenGL;

#configuration
my $PI=3.14159;
my $WINDOW_WIDTH=800;
my $WINDOW_HEIGHT=400;
my $CIRCLE_RESOLUTION=10;
my $EPSILON=0.000001;
my $FPS=60.0;
my $DELAY=1000.0/$FPS;
my $DELTA_TIME_SEC=1.0/$FPS;

my $gl =new GLAM({height=>$WINDOW_HEIGHT,width=>$WINDOW_WIDTH,dt=>$DELTA_TIME_SEC});

my $startPosition=new Vector2($WINDOW_WIDTH/2,$WINDOW_HEIGHT/2);


sub drawObject{
	my $window=shift;
	$window->circle($startPosition,30);
}

$gl->mainLoop(\&update);

sub update{
	my ($app)=@_;
	if($app->key("esc") || $app->key("q")){
		print("goodbye!\n");
		exit(0);
	}
	drawObject($app->{canvas});
}

package GraphicObject;





