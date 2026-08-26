package GLAM;
use strict;
use warnings;

# GLAM    SDL variant
# requires at least perl v5.40 # installed by using
# cpanm SDL3
# complex dependencies which may make installation tricky.  I have an older version of Ubuntu
# 1) Dependencies identified in https://wiki.libsdl.org/SDL3/README-linux
# 2) I needed to  manually install libssl
# https://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.24_amd64.deb
# https://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl-dev_1.1.1f-1ubuntu2.24_amd64.deb
# 3) libpipewire-0.2-1 libjack0 libjack-dev libpipewire-0.2-dev libpulse-dev libsndio7.0  libsndio-dev 



use SDL3 qw[:all];


our $VERSION='0.03';


sub new{
	my ($class,$params)=@_;
	
	SDL_Init(SDL_INIT_VIDEO) || die 'Init Error: ' . SDL_GetError();
	
	my $self={
		height=>$params->{height}//400,
		width=>$params->{width}//800,
		title=>$params->{title}//"GLAM-SDL",
		dt=>$params->{dt}//1.0/60,
		};
	
	$self->{window}   = SDL_CreateWindow($self->{title}, $self->{width}, $self->{height}, 0 );
	$self->{canvas}   = new SDLCanvas($self->{width},$self->{height});
	$self->{renderer} = SDL_CreateRenderer( $self->{window}, undef );
	$self->{last_time}= SDL_GetTicks();
	$self->{event_ptr}= Affix::malloc(128);
	$self->{keyboard}={scancode=>0};;
	$self->{mouse}={x=>0, y=>0,mask=>0 };
	$self->{running}=0;

	bless $self,$class;
	return $self;
	
}

sub mousePosition{
	my $self=shift;
	return Vector2->new($self->{mouse}->{x},$self->{height}-$self->{mouse}->{y});
};

sub button{   # return 1 if pressed, 0 if not 
		my ($self,$btn)=@_;
		return $self->{mouse}->{mask} & SDL_BUTTON_LMASK?1:0   if ($btn eq  "left");
		return $self->{mouse}->{mask} & SDL_BUTTON_RMASK?1:0   if ($btn eq  "right");
	};

sub key{      # return 1 if pressed, 0 if not 
		my ($self,$btn)=@_;
		return unless $self->{keyboard}->{scancode};
		return $self->{keyboard}->{scancode} == SDL_SCANCODE_ESCAPE?1:0     if ($btn eq  "esc");
		return $self->{keyboard}->{scancode} == SDL_SCANCODE_Q?1:0          if ($btn eq  "q");
}

sub mainLoop{
	my ($self,$subRef)=@_;
	$self->{running}=1;
	while($self->{running}){
		my $now = SDL_GetTicks();
		my $dt  = ( $now - $self->{last_time} ) / 1000.0;
		$self->{last_time} = $now;
		my $x=\$self->{mouse}->{x};
		my $y=\$self->{mouse}->{y};
	    $self->{mouse}->{mask} = SDL_GetMouseState($x, $y );
	    

		while ( SDL_PollEvent($self->{event_ptr}) ) {
			$self->{keyboard}->{scancode}=0;
			my $h = Affix::cast( $self->{event_ptr}, SDL_CommonEvent );
			if    ( $h->{type} == SDL_EVENT_QUIT ) { $self->{running} = 0 }
			elsif ( $h->{type} == SDL_EVENT_KEY_DOWN ) {
				my $k = Affix::cast( $self->{event_ptr}, SDL_KeyboardEvent );
				$self->{keyboard}->{scancode}=$k->{scancode};
			}
		}

		SDL_SetRenderDrawColor( $self->{renderer}, 26, 26, 26, 255 );
		SDL_RenderClear($self->{renderer});		
		$self->{canvas}->{verts}=[];
		$subRef->($self);	
		SDL_RenderGeometry( $self->{renderer}, undef, $self->{canvas}->{verts}, scalar(@{$self->{canvas}->{verts}}), undef, 0 );
		SDL_RenderPresent($self->{renderer});
	}
	SDL_DestroyRenderer($self->{renderer});
	SDL_DestroyWindow($self->{window});
	SDL_Quit();
}

package SDLCanvas;

use SDL3 qw[:all];

our $pi=3.14159;

sub new{
	my ($class,$width,$height)=@_;
	my $self={
		width=>$width,
		height=>$height,
		circleRes=>10,
		currentColour=>{ r => 0.5, g => 0.5, b => 0.5 },
		verts=>[],
		objects=>[],
	};
	bless $self, $class;
	return $self;
}


sub colour{
	my ($self,$r,$g,$b,$a)=@_;
	$self->{currentColour}={ r => $r, g => $g, b => $b};
}

sub winTriangle{
	my ($self,$v2a,$v2b,$v2c)=@_;
    push @{$self->{verts}}, map {
		   { position => { x => $_->{x}, y =>  $_->{y} },
			 color => $self->{currentColour},
			 tex_coord => { x => 0, y => 0 } } } $v2a,  $v2b, $v2c;

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


sub thickLine{
	my ($self,$p0,$p1,$t)=@_;

	my $v1=$p1->diff($p0);
	my $v2=$v1->unitNormal()->mul($t/2);
	return unless $v2;

	$self->quad(
	    $p0->add($v2),
	    $p0->diff($v2),
	    $p1->diff($v2),
	    $p1->add($v2)
	    );
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
  if (! defined $x){
    ($self->{x},$self->{y})=(0,0);
  }
	elsif (ref $x eq "ARRAY"){
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
  die "undefined vec2 in caller" . caller() if (!defined $vec2);
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

