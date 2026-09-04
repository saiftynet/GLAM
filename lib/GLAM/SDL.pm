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


our $VERSION='0.04';


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
  $self->{colour}=Misc::setColours();
	bless $self, $class;
	return $self;
}


sub colour{
	my ($self,$r,$g,$b,$a)=@_;
  
  if (ref $r eq "Array"){
    $self->{currentColour}={ r => $r->[0], g => $r->[1], b => $r->[2]};
  }
  elsif(exists $self->{colour}->{$r}){
    $self->colour(Misc::hex2fp($self->{colour}->{$r}));
  }
  else{
    $self->{currentColour}={ r => $r, g => $g, b => $b};
  }
  
  
}

sub winTriangle{
	my ($self,$v2a,$v2b,$v2c)=@_;
    push @{$self->{verts}}, map {
		   { position => { x => $_->{x}, y =>  $_->{y} },
			 color => $self->{currentColour},
			 tex_coord => { x => 0, y => 0 } } } $v2a,  $v2b, $v2c;

}

sub triangle{
	my ($self,$v2a,$v2b,$v2c,$thickness)=@_;
	if (!defined $thickness){
	  $self->winTriangle(
		  Vector2->new($v2a->toSimp($self)->asXY()),
		  Vector2->new($v2b->toSimp($self)->asXY()),
		  Vector2->new($v2c->toSimp($self)->asXY()),
	  )
    }
    else{
      $self->thickLine($v2a,$v2b,$thickness);
      $self->thickLine($v2b,$v2c,$thickness);
      $self->thickLine($v2a,$v2a,$thickness);
      
    }
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
	my ($self,$center,$radius,$thickness,$triangles)=@_;
	my $pi=3.14159;
	$triangles//=10;
	my $STEP_ANGLE=(2*$pi)/($triangles);
	for(0..$triangles-1){
		my $p0=$center;
		my $p1=$p0->delta($radius,$STEP_ANGLE*$_);
		my $p2=$p0->delta($radius,$STEP_ANGLE*($_+1));
		if (!defined $thickness){
      $self->triangle($p0,$p1,$p2);
    }
    else {
      $self->thickLine($p1,$p2,$thickness);
    }
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



package Misc;


sub setColours{
  # extracted from https://htmlcolorcodes.com/color-names/
  return {
indianred       => "CD5C5C", # [0.800,0.359,0.359],
lightcoral      => "F08080", # [0.937,0.500,0.500],
salmon          => "FA8072", # [0.976,0.500,0.445],
darksalmon      => "E9967A", # [0.910,0.585,0.476],
lightsalmon     => "FFA07A", # [0.996,0.625,0.476],
crimson         => "DC143C", # [0.859,0.78,0.234],
red             => "FF0000", # [0.996,0.0,0.0],
firebrick       => "B22222", # [0.695,0.132,0.132],
darkred         => "8B0000", # [0.542,0.0,0.0],
pink            => "FFC0CB", # [0.996,0.750,0.792],
lightpink       => "FFB6C1", # [0.996,0.710,0.753],
hotpink         => "FF69B4", # [0.996,0.410,0.703],
deeppink        => "FF1493", # [0.996,0.78,0.574],
mediumvioletred => "C71585", # [0.777,0.82,0.519],
palevioletred   => "DB7093", # [0.855,0.437,0.574],
lightsalmon     => "FFA07A", # [0.996,0.625,0.476],
coral           => "FF7F50", # [0.996,0.496,0.312],
tomato          => "FF6347", # [0.996,0.386,0.277],
orangered       => "FF4500", # [0.996,0.269,0.0],
darkorange      => "FF8C00", # [0.996,0.546,0.0],
orange          => "FFA500", # [0.996,0.644,0.0],
gold            => "FFD700", # [0.996,0.839,0.0],
yellow          => "FFFF00", # [0.996,0.996,0.0],
lightyellow     => "FFFFE0", # [0.996,0.996,0.875],
lemonchiffon    => "FFFACD", # [0.996,0.976,0.800],
lightgoldenrodyellow => "FAFAD2", # [0.976,0.976,0.820],
papayawhip      => "FFEFD5", # [0.996,0.933,0.832],
moccasin        => "FFE4B5", # [0.996,0.890,0.707],
peachpuff       => "FFDAB9", # [0.996,0.851,0.722],
palegoldenrod   => "EEE8AA", # [0.929,0.906,0.664],
khaki           => "F0E68C", # [0.937,0.898,0.546],
darkkhaki       => "BDB76B", # [0.738,0.714,0.417],
lavender        => "E6E6FA", # [0.898,0.898,0.976],
thistle         => "D8BFD8", # [0.843,0.746,0.843],
plum            => "DDA0DD", # [0.863,0.625,0.863],
violet          => "EE82EE", # [0.929,0.507,0.929],
orchid          => "DA70D6", # [0.851,0.437,0.835],
fuchsia         => "FF00FF", # [0.996,0.0,0.996],
magenta         => "FF00FF", # [0.996,0.0,0.996],
mediumorchid    => "BA55D3", # [0.726,0.332,0.824],
mediumpurple    => "9370DB", # [0.574,0.437,0.855],
rebeccapurple   => "663399", # [0.398,0.199,0.597],
blueviolet      => "8A2BE2", # [0.539,0.167,0.882],
darkviolet      => "9400D3", # [0.578,0.0,0.824],
darkorchid      => "9932CC", # [0.597,0.195,0.796],
darkmagenta     => "8B008B", # [0.542,0.0,0.542],
purple          => "800080", # [0.500,0.0,0.500],
indigo          => "4B0082", # [0.292,0.0,0.507],
slateblue       => "6A5ACD", # [0.414,0.351,0.800],
darkslateblue   => "483D8B", # [0.281,0.238,0.542],
mediumslateblue => "7B68EE", # [0.480,0.406,0.929],
greenyellow     => "ADFF2F", # [0.675,0.996,0.183],
chartreuse      => "7FFF00", # [0.496,0.996,0.0],
lawngreen       => "7CFC00", # [0.484,0.984,0.0],
lime            => "00FF00", # [0.0,0.996,0.0],
limegreen       => "32CD32", # [0.195,0.800,0.195],
palegreen       => "98FB98", # [0.593,0.980,0.593],
lightgreen      => "90EE90", # [0.562,0.929,0.562],
mediumspringgreen => "00FA9A", # [0.0,0.976,0.601],
springgreen     => "00FF7F", # [0.0,0.996,0.496],
mediumseagreen  => "3CB371", # [0.234,0.699,0.441],
seagreen        => "2E8B57", # [0.179,0.542,0.339],
forestgreen     => "228B22", # [0.132,0.542,0.132],
green           => "008000", # [0.0,0.500,0.0],
darkgreen       => "006400", # [0.0,0.390,0.0],
yellowgreen     => "9ACD32", # [0.601,0.800,0.195],
olivedrab       => "6B8E23", # [0.417,0.554,0.136],
olive           => "808000", # [0.500,0.500,0.0],
darkolivegreen  => "556B2F", # [0.332,0.417,0.183],
mediumaquamarine => "66CDAA", # [0.398,0.800,0.664],
darkseagreen    => "8FBC8B", # [0.558,0.734,0.542],
lightseagreen   => "20B2AA", # [0.125,0.695,0.664],
darkcyan        => "008B8B", # [0.0,0.542,0.542],
teal            => "008080", # [0.0,0.500,0.500],
aqua            => "00FFFF", # [0.0,0.996,0.996],
cyan            => "00FFFF", # [0.0,0.996,0.996],
lightcyan       => "E0FFFF", # [0.875,0.996,0.996],
paleturquoise   => "AFEEEE", # [0.683,0.929,0.929],
aquamarine      => "7FFFD4", # [0.496,0.996,0.828],
turquoise       => "40E0D0", # [0.250,0.875,0.812],
mediumturquoise => "48D1CC", # [0.281,0.816,0.796],
darkturquoise   => "00CED1", # [0.0,0.804,0.816],
cadetblue       => "5F9EA0", # [0.371,0.617,0.625],
steelblue       => "4682B4", # [0.273,0.507,0.703],
lightsteelblue  => "B0C4DE", # [0.687,0.765,0.867],
powderblue      => "B0E0E6", # [0.687,0.875,0.898],
lightblue       => "ADD8E6", # [0.675,0.843,0.898],
skyblue         => "87CEEB", # [0.527,0.804,0.917],
lightskyblue    => "87CEFA", # [0.527,0.804,0.976],
deepskyblue     => "00BFFF", # [0.0,0.746,0.996],
dodgerblue      => "1E90FF", # [0.117,0.562,0.996],
cornflowerblue  => "6495ED", # [0.390,0.582,0.925],
mediumslateblue => "7B68EE", # [0.480,0.406,0.929],
royalblue       => "4169E1", # [0.253,0.410,0.878],
blue            => "0000FF", # [0.0,0.0,0.996],
mediumblue      => "0000CD", # [0.0,0.0,0.800],
darkblue        => "00008B", # [0.0,0.0,0.542],
navy            => "000080", # [0.0,0.0,0.500],
midnightblue    => "191970", # [0.97,0.97,0.437],
cornsilk        => "FFF8DC", # [0.996,0.968,0.859],
blanchedalmond  => "FFEBCD", # [0.996,0.917,0.800],
bisque          => "FFE4C4", # [0.996,0.890,0.765],
navajowhite     => "FFDEAD", # [0.996,0.867,0.675],
wheat           => "F5DEB3", # [0.957,0.867,0.699],
burlywood       => "DEB887", # [0.867,0.718,0.527],
tan             => "D2B48C", # [0.820,0.703,0.546],
rosybrown       => "BC8F8F", # [0.734,0.558,0.558],
sandybrown      => "F4A460", # [0.953,0.640,0.375],
goldenrod       => "DAA520", # [0.851,0.644,0.125],
darkgoldenrod   => "B8860B", # [0.718,0.523,0.42],
peru            => "CD853F", # [0.800,0.519,0.246],
chocolate       => "D2691E", # [0.820,0.410,0.117],
saddlebrown     => "8B4513", # [0.542,0.269,0.74],
sienna          => "A0522D", # [0.625,0.320,0.175],
brown           => "A52A2A", # [0.644,0.164,0.164],
maroon          => "800000", # [0.500,0.0,0.0],
white           => "FFFFFF", # [0.996,0.996,0.996],
snow            => "FFFAFA", # [0.996,0.976,0.976],
honeydew        => "F0FFF0", # [0.937,0.996,0.937],
mintcream       => "F5FFFA", # [0.957,0.996,0.976],
azure           => "F0FFFF", # [0.937,0.996,0.996],
aliceblue       => "F0F8FF", # [0.937,0.968,0.996],
ghostwhite      => "F8F8FF", # [0.968,0.968,0.996],
whitesmoke      => "F5F5F5", # [0.957,0.957,0.957],
seashell        => "FFF5EE", # [0.996,0.957,0.929],
beige           => "F5F5DC", # [0.957,0.957,0.859],
oldlace         => "FDF5E6", # [0.988,0.957,0.898],
floralwhite     => "FFFAF0", # [0.996,0.976,0.937],
ivory           => "FFFFF0", # [0.996,0.996,0.937],
antiquewhite    => "FAEBD7", # [0.976,0.917,0.839],
linen           => "FAF0E6", # [0.976,0.937,0.898],
lavenderblush   => "FFF0F5", # [0.996,0.937,0.957],
mistyrose       => "FFE4E1", # [0.996,0.890,0.878],
gainsboro       => "DCDCDC", # [0.859,0.859,0.859],
lightgray       => "D3D3D3", # [0.824,0.824,0.824],
silver          => "C0C0C0", # [0.750,0.750,0.750],
darkgray        => "A9A9A9", # [0.660,0.660,0.660],
gray            => "808080", # [0.500,0.500,0.500],
dimgray         => "696969", # [0.410,0.410,0.410],
lightslategray  => "778899", # [0.464,0.531,0.597],
slategray       => "708090", # [0.437,0.500,0.562],
darkslategray   => "2F4F4F", # [0.183,0.308,0.308],
black           => "000000", # [0.0,0.0,0.0],

    };
}


sub hex2fp{
  my $hex=shift;
  my @segments;
  if (length $hex<5){
    @segments=$hex=~/^(0x|#)?([0-9a-f])([0-9a-f])([0-9a-f])/i;
    $segments[$_].="0" foreach(1..3)
    
  }
  else{
     @segments=$hex=~/^(0x|#)?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i;
  }
  shift @segments;
  return map{hex($_)/256} @segments;
  
}


1;


1;

