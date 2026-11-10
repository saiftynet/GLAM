package Toggle;
use lib "../";
use GLAM::Writer;

our $VERSION='0.05';

sub new{
   my ($class,$id,$position,$size,$text)=@_;
   my $self= {
         id         => $id,
         pos        => new Vector2($position),
         size       => new Vector2($size),
         writer     => new Writer($w),
         value      => 0,
         actions    => {   },
         oncolour   => "lightgreen",
         offcolour    => "pink",
         draggable  => 0,
         parts      => [],
  };
  bless $self,$class;
  $self->buildMe();
  return $self;
}


sub buildMe{
  my ($self)=@_;
  my $p0=$self->{pos};
  my $p1=$p0->add(new Vector2([0,$self->{size}->{y}]));
  my $p2=$p0->add($self->{size});
  my $p3=$p0->add(new Vector2([$self->{size}->{x},0]));
  $self->{parts}=$self->{value}?[["c",$self->{oncolour}],["q",$p0,$p1,$p2,$p3]]:
                                [["c",$self->{offcolour}] ,["q",$p0,$p1,$p2,$p3]];
  
}


sub onmouseover{};

sub onmouseout{};

sub onmouseup{};

sub onmousedown{
  my ($self,$subRef)=@_;
  print "mousedown $self->{id}\n";
  $self->{value}= $self->{value}?0:1;
  $self->{actions}->{onmousedown}->() if (defined $self->{actions}->{onmousedown});
  $self->buildMe();

}




package Toggle;
use lib "../";
use GLAM::Writer;

sub new{
   my ($class,$id,$position,$size,$text)=@_;
   my $self= {
         id         => $id,
         pos        => new Vector2($position),
         size       => new Vector2($size),
         writer     => new Writer($w),
         value      => 0,
         actions    => {   },
         oncolour   => "lightgreen",
         offcolour    => "pink",
         draggable  => 0,
         parts      => [],
  };
  bless $self,$class;
  $self->buildMe();
  return $self;
}


sub buildMe{
  my ($self)=@_;
  my $p0=$self->{pos};
  my $p1=$p0->add(new Vector2([0,$self->{size}->{y}]));
  my $p2=$p0->add($self->{size});
  my $p3=$p0->add(new Vector2([$self->{size}->{x},0]));
  $self->{parts}=$self->{value}?[["c",$self->{oncolour}],["q",$p0,$p1,$p2,$p3]]:
                                [["c",$self->{offcolour}] ,["q",$p0,$p1,$p2,$p3]];
  
}


sub onmouseover{};

sub onmouseout{};

sub onmouseup{};

sub onmousedown{
  my ($self,$subRef)=@_;
  print "mousedown $self->{id}\n";
  $self->{value}= $self->{value}?0:1;
  $self->{actions}->{onmousedown}->() if (defined $self->{actions}->{onmousedown});
  $self->buildMe();

}



package Button;
use lib "../";
use GLAM::Writer;

sub new{
   my ($class,$id,$position,$size,$text)=@_;
   my $self= {
         id         => $id,
         pos        => new Vector2($position),
         size       => new Vector2($size),
         writer     => new Writer($w),
         content    => $text,
         actions    => {   },
         mouseover  => 0,
         mousedown  => 0,
         mouseOverColour     => "cornflowerblue",
         mouseOutColour      => "lightblue",
         colour              => "lightblue",
         labelColour         => "white",
         draggable  => 0,
         parts      => [],
  };
  bless $self,$class;
  $self->buildMe();
  return $self;
}

sub buildMe{
  my ($self)=@_;
  my $p0=$self->{pos};
  my $p1=$p0->add(new Vector2([0,$self->{size}->{y}]));
  my $p2=$p0->add($self->{size});
  my $p3=$p0->add(new Vector2([$self->{size}->{x},0]));
  my $o=new Vector2([5,5]);
  my $p4=$p0->add($o);
  my $p5=$p1->add($o);
  my $p6=$p2->add($o);
  my $p7=$p3->add($o);
  $self->{parts}=$self->{mousedown}?[["c","green"],["q",$p4,$p5,$p6,$p7],
                  ["c",$self->{colour}],
                  ["q",$p0,$p1,$p2,$p3],  ]:
                  [["c","green"],["q",$p0,$p1,$p2,$p3],
                  ["c",$self->{colour}],
                  ["q",$p4,$p5,$p6,$p7],  ] ;
  my $plines=$self->{writer}->at($self->{pos}->add(
                                           $self->{mousedown}?new Vector2([10,1]):
                                           new Vector2([15,6])))
                                        ->setSize(3)
                                        ->strLineSet($self->{content});
  push @{$self->{parts}}, ["c",$self->{labelColour}];
  push @{$self->{parts}}, ["p",$_,$self->{mouseover}?2:1] foreach (@$plines);

};


sub onmousedown{
  my ($self,$subRef)=@_;
  print "mousedown $self->{id}\n";
  $self->{actions}->{onmousedown}->() if (defined $self->{actions}->{onmousedown});
  $self->buildMe();
 # $self->{onclick}=$subRef;  
}

sub onmouseup{
  my ($self,$subRef)=@_;
  print "mouseup $self->{id}\n";
  $self->{actions}->{onmouseup}->() if (defined $self->{actions}->{onmouseup});
  $self->buildMe();
 # $self->{onclick}=$subRef;  
}

sub onmouseover{
  my ($self)=@_;
  print "over $self->{id}\n";
  $self->{colour}=$self->{mouseOverColour};
  $self->{mouseover}=1;
  $self->{actions}->{onmouseover}->() if (defined $self->{actions}->{onmouseover});
  $self->buildMe();
}

sub onmouseout{
  my ($self)=@_;
  print "out of $self->{id}\n";
  $self->{colour}=$self->{mouseOutColour};
  $self->{mouseover}=0;
  $self->buildMe();
}


package  UI;
use lib "../";
use GLAM::Writer;
our $VERSION='0.04';

sub new{
   my ($class,$w)=@_;
   my $self= {w            => $w,
              writer=>new Writer($w),
              elements     => [],
              mousePosition=> [],
	            prevLeftBtn  => 0,
              drag         => 0,
              };
   bless $self,$class;
   return $self;
}

sub interact{
  my ($self,$dt,$mousePosition,$leftbutton)=@_;
  # print $mousePosition->asXY(),"\n";
  foreach my $el (@{$self->{elements}}){ # mouseover
     if ($self->mouseOver($el,$mousePosition)){
       $el->onmouseover() if !$el->{mouseover} ;
       if ($leftbutton){
         $el->{mousedown}=1;
         $el->onmousedown() if !$self->{prevLeftBtn};
       }
       else{
         $el->{mousedown}=0;
         $el->onmouseup() if $self->{prevLeftBtn};
         
       }
     }
     elsif ($el->{mouseover}){  # mouse out , change if was previously over
       $el->onmouseout();
       $el->{mousedown}=0;
     }
  }
  $self->{prevLeftBtn}=$leftbutton;
}

sub mouseOver{
  my ($self,$element,$mousePosition)=@_;
  my $bl=$element->{pos};
  my $tr=$bl->add($element->{size});
  return $mousePosition->inBox($bl,$tr);
}

sub addButton{
  my ($self,$id,$pos,$size,$text,$colour,$colour2)=@_;
  push @{$self->{elements}}, new Button($id,$pos,$size,$text,$colour,$colour2);
  return $self->{elements}->[-1];
}


sub addToggle{
  my ($self,$id,$pos,$size,$text,$colour,$colour2)=@_;
  push @{$self->{elements}}, new Toggle($id,$pos,$size,$text,$colour,$colour2);
  return $self->{elements}->[-1];
}



sub drawUI{
  my ($self)=@_;
  foreach my $el (@{$self->{elements}}){
    $self->{w}->composite($el->{parts});
  };
}

 1;
