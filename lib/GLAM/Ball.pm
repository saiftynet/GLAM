package  Ball;

our $VERSION='0.03';

sub new{
	my ($class,@params)=@_;
	my %p = (ref $params[0])?%{$params[0]}:@params;
	my $self={rad=>$p{rad},
		      col=>$p{col},
		      pos=>$p{pos},
		      vel=>$p{vel}//new Vector2(),
		      mass=>$p{mass}//$p{rad}*$p{rad},
		      sf     => $p{static_friction}  || 0.4, # Resistance to starting motion
		      df     => $p{dynamic_friction} || 0.2, # Resistance during sliding
		      }
	;
		      
	 bless  $self,$class;
	 return $self;

}

sub touches{
	my ($self,$other)=@_;
	return $self->separation($other)  < 0;
}

sub move{
	my ($self,$direction,$units)=@_;
	if (!$units){$self->{pos}=$self->{pos}->add($direction);}
}

sub bounce{
	my ($self,$other,$units)=@_;
	
	my $restitution=$units->{restitution}//0.8;
	
	# unit Normal get displacement from one another, and divide my its magnitude
	# this is sort of different from a normal to a vector...the vector bewteen 
	# the centers of two circles is normal to the tangent of the circles
	my $un=$other->{pos}->diff($self->{pos})->unitVector();

	#relative velocity in direction of normal
	my $relVel=$other->{vel}->diff($self->{vel});
	my $velInNormal=$relVel->dot($un) ;
	
	#___
	# Only resolve if objects are moving toward each other
       if ($velInNormal < 0) {
         
         # Normal Impulse Scalar (j)
         my $j = -(1 + $restitution) * $velInNormal;
         $j /= (1 / $self->{mass} + 1 / $other->{mass});

         # --- STEP C: Friction Impulse ---
         # Tangent vector (perpendicular to normal)
         my $tangent=$un->unitNormal();
         my $velInTangent = $relVel->dot($tangent);
         
         # Friction Impulse Scalar (jt)
         my $jt = -$velInTangent;
         $jt /= (1 / $self->{mass} + 1 / $other->{mass});
         
         # Combine friction coefficients (Pythagorean blend)
         my $sf = sqrt($self->{sf} * $self->{sf} + $other->{sf} * $other->{sf});
         my $df = sqrt($self->{df} * $self->{df} + $other->{df} * $other->{df});

         # Clamp friction impulse using Coulomb's Law (Ff <= mu * Fn)
         my $friction_impulse;
         if (abs($jt) < $j * $sf) {
                        $friction_impulse = $jt; # Static friction holds
         }
         else {
                        $friction_impulse = -$j * $df * ($jt > 0 ? 1 : -1); # Dynamic sliding friction
         }
         
         # Apply Normal + Friction forces together
         $self->{vel}= new Vector2( $self->{vel}->{x}  - (1 / $self->{mass})  * ($j * $un->{x} + $friction_impulse * $tangent->{x}),
                                    $self->{vel}->{y}  - (1 / $self->{mass})  * ($j * $un->{y} + $friction_impulse * $tangent->{y}) );
         $other->{vel}= new Vector2($other->{vel}->{x} + (1 / $other->{mass}) * ($j * $un->{x} + $friction_impulse * $tangent->{x}),
                                    $other->{vel}->{y} + (1 / $other->{mass}) * ($j * $un->{y} + $friction_impulse * $tangent->{y}) );

     }
}

sub boundary{
	my ($self,$boundary)=@_;
	if ($self->{pos}->{x}  <   $boundary->{left} + $self->{rad}) {
		$self->{pos}->{x}  =   $boundary->{left} + $self->{rad};
		$self->{vel}->{x} *=   -1;
	}
	elsif ($self->{pos}->{x} > $boundary->{right} - $self->{rad}){
		   $self->{pos}->{x} = $boundary->{right} - $self->{rad};
		   $self->{vel}->{x} *= -1;
	};

	if ($self->{pos}->{y}  <   $boundary->{bottom} + $self->{rad}) {
		$self->{pos}->{y}  =   $boundary->{bottom} + $self->{rad};
		$self->{vel}->{y} *=   -1;
	}
	elsif ($self->{pos}->{y} > $boundary->{top} - $self->{rad}){
		   $self->{pos}->{y} = $boundary->{top} - $self->{rad};
		   $self->{vel}->{y} *= -1;
	};
}

sub proximity{
	my ($self,$other)=@_;
	return $self->{pos}->diff($other->{pos})->length();
}

sub separation{
	my ($self,$other)=@_;
	return $self->proximity($other) - ($self->{rad} + $other->{rad});
}

sub update{
	my ($self,$dt)=@_;
	$self->{pos}=$self->{pos}->add($self->{vel}->mul($dt));
	# print $self->{pos}->{x},":",$self->{pos}->{y},"\n";
	
}

1;
