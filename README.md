# GLAM
Graphics Layer Abstraction Module

## SYNOPSIS
```
    use GLAM::OpenGL;
    # use GLAM::SDL;

    my $gl =new GLAM({height=>400,width=>800,dt=>1/60});
    my $gameObject =new GameObject($gl->{canvas},$GameParametersAsHashref);
    $gl->mainLoop(\&update);

    sub update{
	   my ($app)=@_;
	   if($app->key("esc") || $app->key("q")){# keys to exit GameLoop
		  print("goodbye!\n");
		  exit(0);
	   }
	   $gameObject->update($app->{dt},<List_of_IO_etc>);
   }

```

## Description

Using interactive graphics typically requires a *Graphics Library*, which provides an API to connect
both user input to the display output.  SDL3 and OpenGL are available to Perl, and have their own Modules
on CPAN.  GLAM attempts to deliver a unified API with common functions e.g. drawing primitives and user input
identical whichever GL is used.  I am not good at programming graphics nor do I code often, so a tool that eases
graphics layer coding may be helpful.  GLAM bundles the IO, graphics primitives and a simple 2d Vector toolkit
in one Module, GLAM::OpenGL for using GLFW (OdenGL), and in the future SDL3.  The code has been adapted from [Reddit
submissions](https://old.reddit.com/r/perl/comments/1vixjm1/tsodings_rope_in_perl/) by [u/First_Ad8230](https://old.reddit.com/user/First_Ad8230) and [u/s_throwaway_r](https://old.reddit.com/user/s_throwaway_r)

## How it works

A GLAM game essentially sets up window,  which is a drawable canvas for graphical elements which, in turn, are merely muliple triangles. these elements are created in a GL agostic way.  The window updates every "tick". At every tick the keyboard and mouse status is collected and is accessible to the Game Logic in consistent way regardless if GL. The game logic has also access to a Vector Math toolkit which will simplify handling the positions of the elements.

## The first program

The [rope demonstration](https://github.com/saiftynet/GLAM/blob/main/Examples/rope-GLAM.pl) that triggered this is the first program that uses GLAM.
A single line can be changed to `use` either `OpenGL` or `SDL`.  


[rope-GLAM.webm](https://github.com/user-attachments/assets/cf62e45c-cc51-46f2-8c4b-91c00df854fb)

## Installation

GLAM depends on the underlying Graphics layer and the corresponding Perl Modules to be installed. The installation of these has not been trivial for me. I would be pleased if someone could provide details of reliable methods for different systems. In mine (Ubuntu 20.04) this worked.

### OpenGL

Needs gl and glfw.

```
    sudo apt install libopengl-perl
    sudo apt install libglfw3
    sudo apt install libglfw3-dev
    sudo cpanm OpenGL OpenGL::GLFW
```

### SDL3

Needs Perl 5.40 minimum. I had to use Perlbrew (something I am not familiar with), and even then I had difficulties. 

1. Install as many of the pre-requisites as possible on the [SDL3 wiki](https://wiki.libsdl.org/SDL3/README-linux).
2. Manually install libraries going to the logs of every attempt as cpanm SDL3 failing.
3. I needed to install `libssl` by installing debs found at [libssl1.1](https://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.24_amd64.deb) and its associated  [`libssl-dev`](https://security.ubuntu.com/ubuntu/pool/main/o/openssl/libssl-dev_1.1.1f-1ubuntu2.24_amd64.deb)
4. `sudo apt install libpipewire-0.2-1 libjack0 libjack-dev libpipewire-0.2-dev libpulse-dev libsndio7.0  libsndio-dev`
5. `sudo apt install libxss1 and libxss-dev`
6. After this `cpanm SDL3` worked for me.


## How GLAM Works
GLAM's operations are subject to change as it is new.
1. When the GLAM object is created it generates a Canvas object which provides a window and graphics drawing primitives.
2. This Canvas Object is passed to the Game Object, along with any initialisation parameters
3. The Game object is initialised.  It stores the Game state, provides the game logic, has an update function that responds to any keys pressed, mouse state, and the time elapsed etc. at each Game loop.
4. When the GLAM's Game loop is started,
   a. does some house keeping,
   b. the loop checks for any end conditions
   c. submits the mouse,keyboard data to the Game Object's logic
   d. the Game object updates its statee, prepares the screen update before returning to the game loop
   e. loop the refreshes the screen buffer etc and continues
   f. if exit condition met GLAM tidies up and exits

## TO DO

The objective is to add features as needed to create any new game.
2D games/tools are created first, and may in the future add more complex functionality.
But all times the objective will remain to produce near identical results whicher graphics back end is used.

## Acknowledgements

* [phanthanhduy](https://github.com/foolish4)
* [Sanko Robinson](https://github.com/sanko)
