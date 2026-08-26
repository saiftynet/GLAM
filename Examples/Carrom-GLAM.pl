use lib "../lib";
use strict;
use warnings;
use Time::HiRes qw(usleep);
use GLAM::OpenGL;   # Change this line to use GLAM::SDL to use SDL3
use GLAM::Ball;





#configuration
my $WINDOW_WIDTH=600;
my $WINDOW_HEIGHT=600;
my $FPS=60.0;
my $DELTA_TIME_SEC=1.0/$FPS;

my $gl =new GLAM({height=>$WINDOW_HEIGHT,width=>$WINDOW_WIDTH,dt=>$DELTA_TIME_SEC});
my $carrom =new Carrom($gl->{canvas},{friction=>.03});
$gl->mainLoop(\&update);

sub update{
	my ($app)=@_;
	if($app->key("esc") || $app->key("q")){
		print("goodbye!\n");
		exit(0);
	}
	$carrom->update($app->{dt},$app->mousePosition(),$app->button("left"));
}



package Carrom;

sub new{
  
  my ($class,$w,$params)=@_;
  my $self={w=>$w,counters=>[],player=>1,scores=>{}};
  $self->{boardPos}=$params->{pos}//[25,25];
  $self->{boardWidth}=$params->{width}//$w->{width}-50;
  $self->{boardWidth}=$params->{height}-50 if ($self->{boardWidth}>$w->{height}-50);
  $self->{friction}=$params->{friction}//0.03;
	$self->{prevLeftBtn}=0;
	$self->{pocketRadius}=25;
  $self->{drag}=0;
	$self->{power}=0;
	$self->{powerDrag}=0;
  $self->{powerLine}=[];
  bless $self,$class;
  
  $self->board();
  $self->counterReset(15);
  $self->strikerReset(20);
  
  
  return $self;
   
}

sub board{
  my $self=shift;
  my $l=$self->{boardPos}->[0];
  my $b=$self->{boardPos}->[1];
  my $r=$self->{boardPos}->[0]+$self->{boardWidth};
  my $t=$self->{boardPos}->[1]+$self->{boardWidth};
  my $rd=$self->{pocketRadius};
  $self->{corners}=[new Vector2($l,$b),new Vector2($l,$t),new Vector2($r,$t), new Vector2($r,$b)];
  $self->{pockets}=[new Vector2($l+$rd,$b+$rd),
                    new Vector2($l+$rd,$t-$rd),
                    new Vector2($r-$rd,$t-$rd),
                    new Vector2($r-$rd,$b+$rd)];
}

sub drawBoard{
  my $self=shift;
  $self->{w}->colour(.3,.5,.7,1);
  $self->{w}->quad(@{$self->{corners}});
  $self->{w}->colour(.1,.1,.1,1);
  foreach (@{$self->{pockets}}){
     $self->{w}->circle($_,$self->{pocketRadius});
  }  
}


sub drawCounter{
  my ($self,$counter)=@_;
	$self->{w}->colour(@{$counter->{col}});
	$self->{w}->circle($counter->{pos},$counter->{rad});
}

sub counterReset{
  my ($self,$r)=@_;
  my $vs=$r*sqrt(3);
  my $w=[255/256,215/256,0];
  my $b=[50/256,50/256,50/256];
  my $m=[256/256,100/256,50/256];
  my ($cx,$cy)=($self->{w}->{width}/2,$self->{w}->{height}/2);
  $self->{counters}=[
                 new Ball({ pos=>  [$cx-$r*2,  $cy-2*$vs]   ,col=>$w, rad=>$r}),
                 new Ball({ pos=>  [$cx,       $cy-2*$vs]   ,col=>$b, rad=>$r}),
                 new Ball({ pos=>  [$cx+$r*2,  $cy-2*$vs]   ,col=>$w, rad=>$r}),
                  
                 new Ball({ pos=>  [$cx-$r*3,  $cy - $vs]   ,col=>$b, rad=>$r}),
                 new Ball({ pos=>  [$cx-$r,    $cy - $vs]   ,col=>$b, rad=>$r}),
                 new Ball({ pos=>  [$cx+$r,    $cy - $vs]   ,col=>$w, rad=>$r}),
                 new Ball({ pos=>  [$cx+$r*3,  $cy - $vs]   ,col=>$b, rad=>$r}),
                  
                 new Ball({ pos=>  [$cx -4*$r, $cy      ]   ,col=>$w, rad=>$r}),
                 new Ball({ pos=>  [$cx - $r*2,$cy      ]   ,col=>$w, rad=>$r}),
                 new Ball({ pos=>  [$cx      , $cy      ]   ,col=>$m, rad=>$r}),
                 new Ball({ pos=>  [$cx + $r*2,$cy      ]   ,col=>$b, rad=>$r}),
                 new Ball({ pos=>  [$cx +4*$r, $cy      ]   ,col=>$w, rad=>$r}),
                  
                 new Ball({ pos=>  [$cx-$r*3,  $cy + $vs]   ,col=>$b, rad=>$r}),
                 new Ball({ pos=>  [$cx-$r,    $cy + $vs]   ,col=>$b, rad=>$r}),
                 new Ball({ pos=>  [$cx+$r,    $cy + $vs]   ,col=>$w, rad=>$r}),
                 new Ball({ pos=>  [$cx+$r*3,  $cy + $vs]   ,col=>$b, rad=>$r}),
                   
                 new Ball({ pos=>  [$cx-$r*2,  $cy+2*$vs]   ,col=>$w, rad=>$r}),
                 new Ball({ pos=>  [$cx,       $cy+2*$vs]   ,col=>$b, rad=>$r}),
                 new Ball({ pos=>  [$cx+$r*2,  $cy+2*$vs]   ,col=>$w, rad=>$r}), ];
}


sub strikerReset{
  my ($self,$r)=@_;
  $self->{striker}= new Ball({pos=> [$self->{w}->{width}/2,60], col=>[.5,.5,0],rad=>$r,vel=>new Vector2()});
}

sub dragStriker{
	my ($self,$newPos)=@_;
	$self->{striker}->{pos}->set($newPos);
  if     ($self->{striker}->{pos}->{x}<$self->{boardPos}->[0]+$self->{striker}->{rad})
         {$self->{striker}->{pos}->{x}=$self->{boardPos}->[0]+$self->{striker}->{rad} }
  elsif  ($self->{striker}->{pos}->{x}>$self->{boardPos}->[0]+$self->{boardWidth}-$self->{striker}->{rad})
         {$self->{striker}->{pos}->{x}=$self->{boardPos}->[0]+$self->{boardWidth}-$self->{striker}->{rad}};
  if     ($self->{striker}->{pos}->{y}<$self->{boardPos}->[1]+$self->{striker}->{rad})
         {$self->{striker}->{pos}->{y}=$self->{boardPos}->[1]+$self->{striker}->{rad} }
  elsif  ($self->{striker}->{pos}->{y}>$self->{boardPos}->[1]+$self->{boardWidth}-$self->{striker}->{rad})
         {$self->{striker}->{pos}->{y}=$self->{boardPos}->[1]+$self->{boardWidth}-$self->{striker}->{rad}};
}


sub dragPower{  # draw the interactive power drag
	my ($self,$mousePos)=@_;
  my $mouseVector=$self->{striker}->{pos}->diff($mousePos);
  my $power=$mouseVector->length();
  $self->{powerLine} =[
      $self->{striker}->{pos}->add($mouseVector->unitVector()->mul($self->{striker}->{rad}+5)),
      $self->{striker}->{pos}->add($mouseVector->unitVector()->mul($self->{striker}->{rad}+5+$power))];
}

sub powerDragRelease{ # shoot the striker
	my ($self,$mousePos)=@_;
  $self->{striker}->{vel}=$self->{striker}->{pos}->diff($mousePos)->mul(10);
  $self->{powerLine} =[];
}


sub render{
	my $self=shift;
  $self->drawBoard();
	foreach (@{$self->{counters}},$self->{striker}){
		$self->drawCounter($_);
	}
  if ($self->{powerDrag}){
	   $self->{w}->colour(.9,0,0,1);
     $self->{w}->thickLine(@{$self->{powerLine}},10) 
   }
}

sub boundary{
	my $self=shift;
	foreach my $ball ($self->{striker},@{$self->{counters}}){
		$ball->boundary({top=>$self->{boardPos}->[1]+$self->{boardWidth},
			               bottom=>$self->{boardPos}->[1],
			               right=>$self->{boardPos}->[1]+$self->{boardWidth},
			               left=>$self->{boardPos}->[0]});
	}
}

sub inPocket{
	my ($self)=@_;
  my @pocketed=();
  foreach my $index (0..$#{$self->{counters}}){
    foreach (@{$self->{pockets}}){
      if ($self->{counters}->[$index]->{pos}->diff($_)->length()<$self->{pocketRadius}){
           print "pocketed $index\n" ;
           push @pocketed,$index ;
       };
    }
  }
  foreach (reverse sort @pocketed){
    splice(@{$self->{counters}}, $_, 1);
  }
  foreach (@{$self->{pockets}}){
      if ($self->{striker}->{pos}->diff($_)->length()<$self->{pocketRadius}){
           print "Striker Pocketed!\n" ;
           $self->strikerReset(20);
       };
    }
  
  
}

sub bounce{
	my $self=shift;
  my @allCounters=($self->{striker},@{$self->{counters}});
  foreach my $start (0..$#allCounters-1){
		foreach my $test($start+1..$#allCounters){
			if ($allCounters[$start]->touches($allCounters[$test])){
				$allCounters[$start]->bounce($allCounters[$test]);

			}
		}
	}
}

sub update{
	my ($self,$dt,$mousePos,$leftButton)=@_;

  $self->drawBoard();
  $self->bounce();
  $self->boundary();
  $self->inPocket();
  my $motion=0;
  $motion+=$_->update($dt,$self->{friction}) foreach ($self->{striker},@{$self->{counters}});
  if ($motion==0){  # $striker can be dragged when all motion stopped
   
    	if ($leftButton           &&
	       !$self->{prevLeftBtn}  &&
	       ($mousePos->diff($self->{striker}->{pos})->length()<$self->{striker}->{rad})
	        ){ $self->{drag}=1;}   
    	elsif ($leftButton           &&
	       !$self->{prevLeftBtn}  &&
	       ($mousePos->diff($self->{striker}->{pos})->length()<$self->{striker}->{rad}+10)
	        ){ $self->{drag}=0; $self->{powerDrag}=1;}
	    elsif(!$leftButton           &&
	       $self->{prevLeftBtn}){
           $self->{drag}=0;
           if ($self->{powerDrag}){
             #print "powerdrag released",$mousePos->diff($self->{striker}->{pos})->length() if $self->{powerDrag};
             $self->{powerDrag}=0;
             $self->powerDragRelease($mousePos);
             
             };
           
           };
         
      $self->{prevLeftBtn}=$leftButton;
	    $self->dragStriker($mousePos) if $self->{drag};
      $self->dragPower($mousePos) if $self->{powerDrag}
      
  }
  
  $self->render();
  
}
