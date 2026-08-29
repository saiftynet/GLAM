# Skeleton Code

```
#!/usr/bin/env perl
# This is the skeleton of the typical GLAM utiity

use lib "../lib";
use strict;
use warnings;
use Time::HiRes qw(usleep);
use GLAM::OpenGL;   # Change this line to use GLAM::SDL to use SDL3
```
The GLAM Module should be in your `@INC`.  The `use lib "../lib"` allows the Glam folder
and its associated files to be placed in a folder called `lib` in the program's directory.

```
# configuration
my $WINDOW_WIDTH=800;
my $WINDOW_HEIGHT=400;
my $FPS=60.0;
my $DELTA_TIME_SEC=1.0/$FPS;

my $gl =new GLAM({height=>$WINDOW_HEIGHT,width=>$WINDOW_WIDTH,dt=>$DELTA_TIME_SEC});
```

GLAM requires the screen dimensions and the delta time to be setup.  This may not be the best way of doing things
and features such as window resizing isn't handled as of version 0.03.

```
my $idea =new Idea($gl->{canvas});
```
The graphical canvas is sent to the Game Object to a allow drawing onto the canvas.

```
$gl->mainLoop(\&update);
```

The Game Loop called passing the update routine.  There are two "update" routines.  One which is passed to GLAM's mainloop
above.  The Game object itself has it's own update routine (see later), which is itself within the mainloop's update subroutine.

```
# the mainloop's update routine
sub update{ 
	my ($app)=@_;
	if($app->key("esc") || $app->key("q")){
		print("goodbye!\n");
		exit(0);
	}
 #The Game Object's update method
	$idea->update($app->{dt},$app->mousePosition(),$app->button("left"));
}
```

## The Game Object

The Game Object is built, typically passing the GLAM's Canvas object as the first parameter.
The Canvas object has the various drawing methods that are used to make the game graphics.
Currently very limited, but hopefully will be extended as development continues

```
package Idea;

sub new{
  my ($class,$w,$params)=@_;
  my $self={w=>$w};
  # initial state
  
  
  bless $self,$class;
  return $self;
}
```
Classical package initiation; this object provides an update method, which
handles any inputs, calls game logic methods, updates the game state, and then
renders the screen.  Typically the render methods is a separate subroutine
that assembles all the other components for the Graphical layer to turn into
a displayed output.


```
sub update{
	my ($self,$dt,$mousePos,$leftButton)=@_;
  
  # parse inputs
  
  # state update
  
  # render screen
  
}

sub render{
  # build screen elements from current state
  
}
```


```
