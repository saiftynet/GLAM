#!/usr/bin/env perl
# This is the initial version of rope-GLAM.pl
# The first demonstration that allows either SDL3 or OpenGL
# to work.

use lib "../lib";
use strict;
use warnings;
use Time::HiRes qw(usleep);
use GLAM::SDL;   # Change this line to use GLAM::SDL to use SDL3
use GLAM::Ball;

#configuration
my $WINDOW_WIDTH=800;
my $WINDOW_HEIGHT=400;
my $CIRCLE_RESOLUTION=10;
my $FPS=60.0;
my $DELTA_TIME_SEC=1.0/$FPS;

my $gl =new GLAM({height=>$WINDOW_HEIGHT,width=>$WINDOW_WIDTH,dt=>$DELTA_TIME_SEC});
my $bounce =new Bounce($gl->{canvas},{number=>20});
$_->{vel}=new Vector2 (rand()*1000-500,rand()*1000-500)  foreach (@{$bounce->{balls}});
$gl->mainLoop(\&update);

sub update{
	my ($app)=@_;
	if($app->key("esc") || $app->key("q")){
		print("goodbye!\n");
		exit(0);
	}
	$bounce->update($app->{dt},$app->mousePosition(),$app->button("left"));
}


package Bounce;

sub new{
	my ($class,$w,$params)=@_;
	my $self={w=>$w};
	$self->{count}=$params->{number}//1;
	$self->{balls}=[];
    bless $self,$class;
	$self->newRandBall() foreach (1..$self->{count});
    return $self;
}

sub render{
	my $self=shift;
	foreach (@{$self->{balls}}){
		$self->{w}->colour(@{$_->{col}});
		$self->{w}->circle($_->{pos},$_->{rad});
	}
}

sub newRandBall{
	my $self=shift;
	my $radius=4+(int(rand()*20));
	my $colour=[rand(),rand(),rand()];
	my $position=new Vector2($radius*2+(($self->{w}->{width}-$radius*4)*rand()),
	                         $radius*2+(($self->{w}->{height}-$radius*4)*rand()));
	push @{$self->{balls}}, new Ball({rad=>$radius,col=>$colour,pos=>$position});
	
}

sub bounce{
	my $self=shift;
	
    foreach my $start (0..$#{$self->{balls}}-1){
		foreach my $test($start+1..$#{$self->{balls}}){
			if ($self->{balls}->[$start]->touches($self->{balls}->[$test])){
			#	print "$start touches $test\n ", ;
			#   $self->{balls}->[$start]->{col}=[rand(),rand(),rand()];
				$self->{balls}->[$start]->bounce($self->{balls}->[$test]);
			}
		}
	}
}

sub boundary{
	my $self=shift;
	foreach my $ball (@{$self->{balls}}){
		$ball->boundary({top=>$self->{w}->{height},
			             bottom=>0,
			             right=>$self->{w}->{width},
			             left=>0});
	}
}

sub update{
	my ($self,$dt,$mousePos,$leftButton)=@_;
	$self->bounce();
	# game logic goes here
	$self->{balls}->[$_]->update($dt) foreach  (0..$#{$self->{balls}});
	$self->boundary();
	
	$self->render();

}


