use lib "../lib";
use strict;
use warnings;
use Time::HiRes qw(usleep);
use GLAM::OpenGL;   # Change this line to use GLAM::SDL to use SDL3
use GLAM::Ball;     # The 2d Ball (so really a disk) physics engine

#configuration
my $WINDOW_WIDTH=600;
my $WINDOW_HEIGHT=600;
my $FPS=60.0;
my $DELTA_TIME_SEC=1.0/$FPS;

my $gl =new GLAM({height=>$WINDOW_HEIGHT,width=>$WINDOW_WIDTH,dt=>$DELTA_TIME_SEC});
my $carrom =new Carrom($gl->{canvas},{friction=>.03,width=>500, pos=>[50,25]});
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
  $self->{boardPos}    =  $params->{pos}//[25,25];
  $self->{boardWidth}  =  $params->{width}//$w->{width}-50;
  $self->{boardWidth}  =  $params->{height}-50 if ($self->{boardWidth}>$w->{height}-50);
  $self->{friction}    =  $params->{friction}//0.03;
	$self->{pocketRadius}=  $params->{pocketRadius}// 25;
	$self->{prevLeftBtn}=0;
  $self->{drag}=0;
  $self->{ballInPlay}=0;
	$self->{power}=0;
	$self->{powerDrag}=0;
  $self->{powerLine}=[];
  $self->{currentPlayer}=1;
  $self->{pocketed}=     {white=>0,red=>0,black=>0,striker=>0};
  $self->{unallocated}=  {white=>0,red=>0,black=>0,striker=>0};
  $self->{playerCounter}={1=>{counters=>[],target=>""},
                          2=>{counters=>[],target=>""},
                          3=>{counters=>[],target=>""},
                          4=>{counters=>[],target=>""}};
  $self->{winner}=0;
  $self->{shot}=0;
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
  $self->{lines}  = [ [ new Vector2($l+55,$b+90), new Vector2($l+55,$t-90)],
                      [ new Vector2($l+75,$b+90), new Vector2($l+75,$t-90)],
                      [ new Vector2($l+90,$b+55), new Vector2($r-90,$b+55)],
                      [ new Vector2($l+90,$b+75), new Vector2($r-90,$b+75)],
                      
                      [ new Vector2($r-55,$b+90), new Vector2($r-55,$t-90)],
                      [ new Vector2($r-75,$b+90), new Vector2($r-75,$t-90)],
                      [ new Vector2($l+90,$t-55), new Vector2($r-90,$t-55)],
                      [ new Vector2($l+90,$t-75), new Vector2($r-90,$t-75)],
                      
                      
                      [ new Vector2($l+91,$t-90), new Vector2($l+180,$t-180)],
                      [ new Vector2($l+90,$b+90), new Vector2($l+180,$b+180)],
                      [ new Vector2($r-90,$t-90), new Vector2($r-180,$t-180)],
                      [ new Vector2($r-90,$b+90), new Vector2($r-180,$b+180)],
                      
                      
                      
                    ];
  $self->{rounds} =  [  new Vector2($l+65,$b+90), new Vector2($l+65,$t-90),         
                        new Vector2($l+90,$b+65), new Vector2($r-90,$b+65),
                        new Vector2($r-65,$b+90), new Vector2($r-65,$t-90),
                        new Vector2($l+90,$t-65), new Vector2($r-90,$t-65)];
}


sub drawBoard{
  my $self=shift;
  $self->{w}->colour(.3,.5,.7,1);
  $self->{w}->quad(@{$self->{corners}});
  $self->{w}->colour(.1,.1,.1,1);
  foreach (@{$self->{pockets}}){
     $self->{w}->circle($_,$self->{pocketRadius});
  }  
  $self->{w}->colour(.1,.5,.1,1);
  foreach my $l (@{$self->{lines}}){
     $self->{w}->thickLine($l->[0],$l->[1],2);
  }  
  foreach my $r (@{$self->{rounds}}){
     $self->{w}->circle($r,10,2);
  }  
}


sub drawCounter{
  my ($self,$counter)=@_;
	$self->{w}->colour(@{$counter->{col}});
	$self->{w}->circle($counter->{pos},$counter->{rad},undef,20);
	$self->{w}->colour(map {$_-.1}@{$counter->{col}});
  # avoid drawing all the decorations if balls moving
  # to reduce extra calculations
  if (!$self->{ballsInPlay}){  
    $self->{w}->circle($counter->{pos},$counter->{rad},2);
    $self->{w}->circle($counter->{pos},$counter->{rad}-4,3);
  }
}

sub counterReset{
  my ($self,$r)=@_;
  my $vs=$r*sqrt(3);
  my $theme={
      "white"=>[255/256,215/256,0],
      "black"=>[50/256,50/256,50/256],
      "red"=>[256/256,100/256,50/256],
  };

  my ($cx,$cy)=($self->{boardPos}->[0]+$self->{boardWidth}/2,$self->{boardPos}->[1]+$self->{boardWidth}/2);
  $self->{counters}=[
                 new Ball({ pos=>  [$cx-$r*2,  $cy-2*$vs]   ,col=>$theme->{white}, rad=>$r}),
                 new Ball({ pos=>  [$cx,       $cy-2*$vs]   ,col=>$theme->{black}, rad=>$r}),
                 new Ball({ pos=>  [$cx+$r*2,  $cy-2*$vs]   ,col=>$theme->{white}, rad=>$r}),
                  
                 new Ball({ pos=>  [$cx-$r*3,  $cy - $vs]   ,col=>$theme->{black}, rad=>$r}),
                 new Ball({ pos=>  [$cx-$r,    $cy - $vs]   ,col=>$theme->{black}, rad=>$r}),
                 new Ball({ pos=>  [$cx+$r,    $cy - $vs]   ,col=>$theme->{white}, rad=>$r}),
                 new Ball({ pos=>  [$cx+$r*3,  $cy - $vs]   ,col=>$theme->{black}, rad=>$r}),
                  
                 new Ball({ pos=>  [$cx -4*$r, $cy      ]   ,col=>$theme->{white}, rad=>$r}),
                 new Ball({ pos=>  [$cx - $r*2,$cy      ]   ,col=>$theme->{white}, rad=>$r}),
                 new Ball({ pos=>  [$cx      , $cy      ]   ,col=>$theme->{red}, rad=>$r}),
                 new Ball({ pos=>  [$cx + $r*2,$cy      ]   ,col=>$theme->{black}, rad=>$r}),
                 new Ball({ pos=>  [$cx +4*$r, $cy      ]   ,col=>$theme->{white}, rad=>$r}),
                  
                 new Ball({ pos=>  [$cx-$r*3,  $cy + $vs]   ,col=>$theme->{black}, rad=>$r}),
                 new Ball({ pos=>  [$cx-$r,    $cy + $vs]   ,col=>$theme->{black}, rad=>$r}),
                 new Ball({ pos=>  [$cx+$r,    $cy + $vs]   ,col=>$theme->{white}, rad=>$r}),
                 new Ball({ pos=>  [$cx+$r*3,  $cy + $vs]   ,col=>$theme->{black}, rad=>$r}),
                   
                 new Ball({ pos=>  [$cx-$r*2,  $cy+2*$vs]   ,col=>$theme->{white}, rad=>$r}),
                 new Ball({ pos=>  [$cx,       $cy+2*$vs]   ,col=>$theme->{black}, rad=>$r}),
                 new Ball({ pos=>  [$cx+$r*2,  $cy+2*$vs]   ,col=>$theme->{white}, rad=>$r}), ];
}

sub strikerReset{
  my ($self,$r)=@_;
  $self->{striker}= new Ball({pos=> [$self->{w}->{width}/2,60], col=>[.5,.5,0],rad=>$r,vel=>new Vector2()});
}

sub dragStriker{  # drag to mousepointer, but not off the board
	my ($self,$newPos)=@_;
	$self->{striker}->{pos}->set($newPos);   
  $self->{striker}->boundary({top=>$self->{boardPos}->[1]+$self->{boardWidth},
			                        bottom=>$self->{boardPos}->[1],
			                        right=>$self->{boardPos}->[0]+$self->{boardWidth},
			                        left=>$self->{boardPos}->[0]});
}


# striher must be positioned in the current player's side, touching both horizontal lines,
# but not touching any other counters
sub validStrikerPlacement{ 
  
  
}

# when striker pocketed one of his counters is placed back to the middle 
# if the "queen" is pocketed, the next shot must pocket a counter for the player
# or the queen is returned  
sub putBackCounter{
	my ($self,$colour)=@_;
  my ($cx,$cy)=($self->{boardPos}->[0]+$self->{boardWidth}/2,$self->{boardPos}->[1]+$self->{boardWidth}/2);
  my $theme={
      "white"=>[255/256,215/256,0],
      "black"=>[50/256,50/256,50/256],
      "red"=>[256/256,100/256,50/256],
  };
  push @{$self->{counters}}, new Ball({ pos=>[$cx,$cy],col=>$theme->{$colour}, rad=>15});
  
}

# Who plays next.


sub dragPower{  # draw the interactive power drag
	my ($self,$mousePos)=@_;
  my $mouseVector=$self->{striker}->{pos}->diff($mousePos);
  my $power=$mouseVector->length();
  $self->{powerLine} =[
      $self->{striker}->{pos}->add($mouseVector->unitVector()->mul($self->{striker}->{rad}+5)),
      $self->{striker}->{pos}->add($mouseVector->unitVector()->mul($self->{striker}->{rad}+5+$power))];
}

sub powerDragRelease{         # shoot the striker
	my ($self,$mousePos)=@_;
  $self->{powerLine} =[];     #stop draing the powerline
  my $mouseVector=$self->{striker}->{pos}->diff($mousePos);
  return if $mouseVector->length() < $self->{striker}->{rad}+5;
  $self->{striker}->{vel}=$self->{striker}->{pos}->diff($mousePos)->mul(15);
  $self->{shot}=1;
}


sub render{
	my $self=shift;
  $self->drawBoard();
	foreach (@{$self->{counters}},$self->{striker}){
		$self->drawCounter($_);
	}
  if ($self->{powerDrag}){
	   $self->{w}->colour("red");
     $self->{w}->thickLine(@{$self->{powerLine}},10) 
   }
}

sub boundary{
	my $self=shift;
	foreach my $ball ($self->{striker},@{$self->{counters}}){
		$ball->boundary({top=>$self->{boardPos}->[1]+$self->{boardWidth},
			               bottom=>$self->{boardPos}->[1],
			               right=>$self->{boardPos}->[0]+$self->{boardWidth},
			               left=>$self->{boardPos}->[0]});
	}
}

sub inPocket{
	my ($self)=@_;
  my @pocketed;
  foreach my $index (0..$#{$self->{counters}}){
    foreach (@{$self->{pockets}}){
      if ($self->{counters}->[$index]->{pos}->diff($_)->length()<$self->{pocketRadius}){
           my $colour =$self->{counters}->[$index]->{col}->[0]==255/256?"white": 
                       $self->{counters}->[$index]->{col}->[0]==50/256 ?"black":
                       "red";
           print "Player $self->{currentPlayer} pocketed $colour counter\n" ;
           $self->{pocketed}->{$colour}++;
           push @pocketed,$index;
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
           $self->{pocketed}->{striker}=1; 
           last;
       };
    }  
}

sub nothingPocketed{
	my $self=shift;
  return ($self->{pocketed}->{black}+$self->{pocketed}->{white}+$self->{pocketed}->{red}+$self->{pocketed}->{striker}) ==0;
}

sub targetPocketed{
	my $self=shift;
  my $cp=$self->{currentPlayer};
  my $cpState=$self->{playerCounter}->{$cp};
  my $target=$cpState->{target};
  my $success=0;
  for (qw/white black red/){
         $self->{unallocated}->{$_}+=$self->{pocketed}->{$_};
  };
  
  ### Striker pocketed foul
  if ($self->{pocketed}->{striker}){
    if ($self->{unallocated}->{red}){
      $self->{unallocated}->{red}=0;
      $self->putBackCounter("red");
    };
    # return a counter if striker pocketed and the player has a target counter
    if ($target ne ""){
         if ($self->{unallocated}->{$target}){
           $self->{unallocated}->{$target}--;
           $self->putBackCounter($target);
         }
         elsif (@{$cpState->{counters}}){
           my $col= shift @{$cpState->{counters}};
           $self->putBackCounter($col);
         }
      }
      # regardless of target; if last counter pocketed by player was red, it is returned
      # also returned if it is the only colour left;
      if (@{$cpState->{counters}} && $cpState->{counters}->[-1] eq "red"){
           my $col= pop @{$cpState->{counters}};
           $self->putBackCounter($col);
      }
    }
    
    
    elsif ($target eq ""){# no colours allocated, so any colour is acceptable
     # if both white and black are pocketed, we can not yet allocate colours
      if ($self->{pocketed}->{white}  && $self->{pocketed}->{black}){
        $success=1;
      }
    # if either white or black os pocketed we can start allocating counters
      elsif($self->{pocketed}->{white} || $self->{pocketed}->{black}){
        $cpState->{target}=$self->{pocketed}->{white}?"white":"black";
        $self->{playerCounter}->{$self->otherPlayer()  }->{target}=$self->{pocketed}->{white}?"black":"white";
        print  "Player $self->{currentPlayer} now playing for  $cpState->{target}\n";
        print  "Player ".$self->otherPlayer()." now playing for  ". $self->{playerCounter}->{$self->otherPlayer()}->{target}."\n";
        $success=1;
      }
      elsif ($self->{pocketed}->{red}){
        $success=1;
      }
    }
    # target already defined, so pocket either target colour or red is success
    elsif ($self->{pocketed}->{$target}  || $self->{pocketed}->{red}) {
        $success = 1 ;
    }
    # otherwise failed, so any uncovered red must be returned
    else{
      if ($self->{unallocated}->{red}){
       $self->{unallocated}->{red}=0;
       $self->putBackCounter("red");
      }
      elsif (@{$cpState->{counters}} && $cpState->{counters}->[-1] eq "red"){
           my $col= pop @{$cpState->{counters}};
           $self->putBackCounter($col);
      }
    }
    
    
    # target is defined now can allocate the counters
    if ($target ne ""){
      foreach (1..2){
        my $ctr=$self->{playerCounter}->{$_}->{target};
        die $ctr unless $ctr;
        push @{$self->{playerCounter}->{$_}->{counters}},($ctr) x $self->{unallocated}->{$ctr};
       }
       $self->{unallocated}=  {white=>0,red=>0,black=>0,striker=>0};
     }
     else{
       $self->{unallocated}->{red}=0;
     }
     push @{$cpState->{counters}}, "red" if $self->{pocketed}->{red};
  
 
  
  # reset the pocketed count
  $self->{pocketed}=     {white=>0,red=>0,black=>0,striker=>0};

  # red counters that are pocket are put on "standby".
  # Another target colour has to be pocketed in the next shot to keep the red
  # otherwise the red is returned to the center spot. keep the 

  
  return $success;
  
}

sub otherPlayer{
	my $self=shift;
  return $self->{currentPlayer}==1?2:1;
}

sub bounce{
	my $self=shift;
  my @allCounters=(@{$self->{counters}});
  unshift @allCounters,$self->{striker} unless $self->{pocketed}->{striker};
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
  
  $self->{ballsInPlay}=0;
  $self->{ballsInPlay}+=$_->update($dt,$self->{friction}) foreach ($self->{striker},@{$self->{counters}});
    
  if ($self->{ballsInPlay}==0){  # $striker can be dragged when all motion stopped
      if ($self->{shot}){      # striker shot
        my $success=$self->targetPocketed() &! $self->{pocketed}->{striker};
        if ($self->{pocketed}->{striker}){
          print "Foul committed\n";
          $self->{pocketed}->{striker}=0;
        };
        $self->{shot}=0;        # ready to shoot again 
        $self->{currentPlayer}=$self->otherPlayer() unless $success;
        foreach my $pl(1..2){
          my $count=0;my $red=0;
          print "Player $pl has ";
          foreach (@{ $self->{playerCounter}->{$pl}->{counters}}){
            if ($_ eq "red") {$red=1;} else {$count++}
          }
          print "$count ".$self->{playerCounter}->{$pl}->{target}. " counters ";
          print $red ? "and the Queen\n":"\n";
          $self->{winner}= $pl if ($count >8);
        }
        if ($self->{winner}){
          print "*** Player $self->{winner} has won ***\n Another Game?\n"; 
          
        }
        else{
          print "Player $self->{currentPlayer}'s turn\n";
        }
      }
      if ($self->{winner}){
        if ($leftButton){
          $self->board();
          $self->counterReset(15);
          $self->strikerReset(20);
          $self->{winner}=0
        }
        else{
          exit(0);
        }
      }
    	elsif ($leftButton           &&
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
  else{
    $self->drawBoard();
    $self->bounce();
    $self->boundary();
    $self->inPocket();
    
    
  }
    $self->render();
  
  
}
