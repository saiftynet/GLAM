#!/usr/bin/env perl
# This is the initial version of rope-GLAM.pl
# The first demonstration that allows either SDL3 or OpenGL
# to work.

use lib "../lib";
use strict;
use warnings;
use Time::HiRes qw(usleep);
use GLAM::OpenGL;   # Change this line to use GLAM::SDL to use SDL3

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
my $rope =new Rope($gl->{canvas},{knotRadius=>10,ropeThickness=>5,segLength=>20,tailLength=>10});
$gl->mainLoop(\&update);

sub update{
	my ($app)=@_;
	if($app->key("esc") || $app->key("q")){
		print("goodbye!\n");
		exit(0);
	}
	$rope->update($app->{dt},$app->mousePosition(),$app->button("left"));
}


package Rope;

sub new{
	my ($class,$w,$params)=@_;
	my $self={w=>$w};
	$self->{knotRadius}   =$params->{knotRadius}//30;
	$self->{ropeThickness}=$params->{ropeThickness}//30;
	$self->{segLength}    =$params->{segLength}//100;
	$self->{elasticity}   =$params->{elasticity}//50;;
	$self->{tailLength}   =$params->{tailLength}//8;;
	$self->{head}=new Vector2($w->{width}/2,$w->{height}/2);
	$self->{prevLeftBtn}=0;
	$self->{drag}=0;
	
	$self->{tail}=[];
	$self->{tail}->[$_]=Vector2->new(rand()*$w->{width},rand()*$w->{height})
            for(0..$self->{tailLength}-1);            
    $self->{tail_velocity}=[];
    $self->{tail_velocity}->[$_]=Vector2->new() for(0..$self->{tailLength}-1);
    bless $self,$class;
    return $self;
}

sub render{
	my $self=shift;
	$self->{w}->colour(0.5,0.5,0.5);
	$self->{w}->thickLine($self->{head},$self->{tail}->[0],$self->{ropeThickness});

	$self->{w}->colour(0.5,0.5,0.5);
	for(1..$self->{tailLength}-1){
		$self->{w}->thickLine($self->{tail}->[$_-1],$self->{tail}->[$_],$self->{ropeThickness});
	}

	$self->{w}->colour(1.0,0.0,0.0);
	$self->{w}->circle($self->{head},$self->{knotRadius});

	$self->{w}->colour(0.0,1.0,0.0);
	for(0..$self->{tailLength}-1){
		$self->{w}->circle($self->{tail}->[$_],$self->{knotRadius});
	}
	
}

sub compute_tail_velocity{
	my ($self,$node1,$node2)=@_;	

	my $tail_velocity=Vector2->new();
	
	my $len=$node2->diff($node1)->length();
	my $target=Vector2->new();
	my $dir=Vector2->new(1,0);

	if($len>0.000001){
		$dir=$node2->diff($node1)->div($len);
	}
	
	$target=$node1->add($dir->mul($self->{segLength}));

	$tail_velocity=($target->diff($node2))->mul($self->{elasticity});

	return $tail_velocity;
}

sub update{
	my ($self,$dt,$mousePos,$leftButton)=@_;
	if ($leftButton           &&
	   !$self->{prevLeftBtn}  &&
	   ($mousePos->diff($self->{head})->length()<$self->{knotRadius})
	   ){ $self->{drag}=1;}
	elsif(!$leftButton           &&
	       $self->{prevLeftBtn}){$self->{drag}=0};
	$self->{prevLeftBtn}=$leftButton;
	$self->dragHead($mousePos) if $self->{drag};
	$self->updateTail($dt);
	$self->render();
}

sub dragHead{
	my ($self,$newPos)=@_;
	$self->{head}->set($newPos);
}

sub updateTail{
	my  ($self,$dt)=@_;	
	$self->{tail_velocity}->[0]=$self->compute_tail_velocity($self->{head},$self->{tail}->[0]);
	
	for(1..$self->{tailLength}-1){
		$self->{tail_velocity}->[$_]=$self->compute_tail_velocity($self->{tail}->[$_-1],$self->{tail}->[$_]);
	}

	for(0..$self->{tailLength}-1){
		$self->{tail}->[$_]=$self->{tail}->[$_]->add($self->{tail_velocity}->[$_]->mul($dt));
	}
}


