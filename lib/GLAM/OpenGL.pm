package GLAM;

#!/usr/bin/env perl
# GLAM    OpenGL variant
# Needs gl and glfw
# sudo apt install libopengl-perl
# sudo apt install libglfw3
# sudo apt install libglfw3-dev
# sudo cpanm OpenGL OpenGL::GLFW

use OpenGL;
use OpenGL::GLFW qw(:all);


our $VERSION='0.03';

sub new{
	my ($class,$params)=@_;
	
	glfwInit();
	my $self={
		height=>$params->{height}//400,
		width=>$params->{width}//800,
		title=>$params->{title}//"GLAM-OpenGL",
		dt=>$params->{dt}//1.0/60,
		
		};
	
	$self->{window}=glfwCreateWindow($self->{width},$self->{height},$self->{title},NULL,NULL);
	$self->{canvas}=new GLCanvas($self->{width},$self->{height});
	$self->{keyboard}={};
	$self->{mouse}={};

	glfwMakeContextCurrent($self->{window});
	glClearColor(0.1,0.1,0.1,1.0);
	glfwSwapInterval(1);
	bless $self,$class;
	return $self;
	
}


sub mousePosition{
	my $self=shift;
		my ($x,$y)=glfwGetCursorPos($self->{window});
		return Vector2->new($x,$self->{height}-$y);
};

sub button{   # return 1 if pressed, 0 if not 
		my ($self,$btn)=@_;
		return glfwGetMouseButton($self->{window},GLFW_MOUSE_BUTTON_LEFT)  if ($btn eq  "left");
		return glfwGetMouseButton($self->{window},GLFW_MOUSE_BUTTON_RIGHT) if ($btn eq  "right");
	};

sub key{      # return 1 if pressed, 0 if not 
		my ($self,$btn)=@_;
		return glfwGetKey($self->{window},GLFW_KEY_ESCAPE)                if ($btn eq  "esc");
		return glfwGetKey($self->{window},GLFW_KEY_Q)                     if ($btn eq  "q");
}

sub mainLoop{
	my ($self,$subRef)=@_;
	while(!glfwWindowShouldClose($self->{window})){
		glClear(GL_COLOR_BUFFER_BIT);
		

		$subRef->($self);

		glfwSwapBuffers($self->{window});
		glfwPollEvents();
	}
	
}

package GLCanvas;
use OpenGL;

our $pi=3.14159;

sub new{
	my ($class,$width,$height)=@_;
	my $self={
		width=>$width,
		height=>$height,
		circleRes=>10,
		objects=>[],
	};
	bless $self, $class;
	return $self;
}


sub thickLine{
	my ($self,$p0,$p1,$t)=@_;

	my $v1=$p1->diff($p0);
	my $v2=$v1->unitNormal()->mul($t/2);
	return unless $v2->length()>0.0001;

	$self->quad(
	    $p0->add($v2),
	    $p0->diff($v2),
	    $p1->diff($v2),
	    $p1->add($v2)
	    );
}

sub colour{
	my ($self,$r,$g,$b,$a)=@_;
	glColor3f($r,$g,$b);
}

sub winTriangle{
	my ($self,$v2a,$v2b,$v2c)=@_;

	glBegin(GL_TRIANGLES);
	{
		glVertex2f($v2a->toOpenGL($self)->asXY());
		glVertex2f($v2b->toOpenGL($self)->asXY());
		glVertex2f($v2c->toOpenGL($self)->asXY());
	}
	glEnd();
}

sub triangle{
	my ($self,$v2a,$v2b,$v2c)=@_;

	$self->winTriangle(
		Vector2->new($v2a->toSimp($self)->asXY()),
		Vector2->new($v2b->toSimp($self)->asXY()),
		Vector2->new($v2c->toSimp($self)->asXY()),
	    );
}


sub quad{
	my ($self,$p0,$p1,$p2,$p3)=@_;
	$self->triangle($p0,$p1,$p2);
	$self->triangle($p0,$p2,$p3);
}


sub circle{
	my ($self,$center,$radius,$triangles)=@_;
	my $pi=3.14159;
	$triangles//=10;
	my $STEP_ANGLE=(2*$pi)/($triangles);
	for(0..$triangles-1){
		my $p0=$center;
		my $p1=$p0->delta($radius,$STEP_ANGLE*$_);
		my $p2=$p0->delta($radius,$STEP_ANGLE*($_+1));
		$self->triangle($p0,$p1,$p2);
	}
}



package Vector2;

sub new{
	my ($class,$x,$y)=@_;
	my $self={};
  bless($self,$class);
  $self->set($x,$y);
	return $self;
}

sub set{
	my ($self,$x,$y)=@_;
	if (ref $x eq "ARRAY"){
		($self->{x},$self->{y})=@$x;
	}
	elsif((ref $x eq "HASH")||(ref $x eq "Vector2")){
		($self->{x},$self->{y})=($x->{x},$x->{y});
	}
	else{
		($self->{x},$self->{y})=($x,$y);
	}
	return $self;
}

sub unitNormal{ # to a vector
	my ($self)=@_;
	return unless $self->length()>0.000001;
	return new Vector2(-$self->{y}/$self->length(),$self->{x}/$self->length());
	
}

sub unitVector{
	my ($self)=@_;
	my $distance=$self->length();
	$distance = 0.0001 if $distance == 0;
	return $self->div($distance);
}

sub diff{
	my ($self,$vec2)=@_;
	return new Vector2($self->{x}-$vec2->{x},$self->{y}-$vec2->{y});	
}

sub delta{ # given angle and distance from a point;
	my ($self,$distance,$angle)=@_;
	return new Vector2(cos($angle),sin($angle))->mul($distance)->add($self);
}

sub add{ # add
	my ($self,$vec2)=@_;
	return new Vector2($vec2->{x}+$self->{x},$vec2->{y}+$self->{y});	
}


sub mul{ # mutiplies
	my ($self,$m)=@_;
	return new Vector2($self->{x}*$m,$self->{y}*$m);	
}


sub div{ # divides 
	my ($self,$d)=@_;
	return new Vector2($self->{x}/$d,$self->{y}/$d);	
}


sub dot{ #dot product
	my ($self,$d)=@_;
	return $self->{x}*$d->{x}+$self->{y}*$d->{y};		
}

sub length{ # vector magnitude
	my ($self)=@_;
	return sqrt((($self->{x})**2)+(($self->{y})**2));
}


# conversion routines
sub toOpenGL{
	my ($self,$window)=@_;
	return new Vector2(
	    ($self->{x}/$window->{width})*2.0-1.0,
	    (($self->{y}/$window->{height})*2.0-1.0)*(-1));
}

sub toSimp{
	my ($self,$window)=@_;
	return new Vector2(
	    $self->{x},
	    $window->{height}-$self->{y});
}

sub asXY{
   my ($self)=@_;
   return ($self->{x},$self->{y});
}

1;
