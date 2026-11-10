


package Logo;

sub new{
   my ($class,@script)=@_;
   my $lines=map {ref $_?(@$_):split(/(\s*[;\n]\s*)/,$_)}@script;
   
   my $self=>{lines=>$lines}
   bless $self, $class;
   return $self;

} 
