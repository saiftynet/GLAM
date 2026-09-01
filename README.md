# GLAM
Graphics Layer Abstraction Module
<img width="965" height="414" alt="GLAM" src="https://github.com/user-attachments/assets/6d00b1fb-1d69-416d-bd7f-96250a4cfc52" />


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
in one Module, GLAM::OpenGL for using GLFW (OpenGL), and GLAM::SDL for SDL3.  The code has been adapted from [Reddit
submissions](https://old.reddit.com/r/perl/comments/1vixjm1/tsodings_rope_in_perl/) by [u/First_Ad8230](https://old.reddit.com/user/First_Ad8230) and [u/s_throwaway_r](https://old.reddit.com/user/s_throwaway_r)

## How it works

A GLAM game essentially sets up window,  which is a drawable canvas for graphical elements which, in turn, are merely muliple triangles. these elements are created in a GL agostic way.  The window updates every "tick". At every tick the keyboard and mouse status is collected and is accessible to the Game Logic in consistent way regardless if GL. The game logic has also access to a Vector Math toolkit which will simplify handling the positions of the elements.

A basic [Ho-To](https://github.com/saiftynet/GLAM/blob/main/How%20To%20Use.md) is provided, along with an example [skeleton](https://github.com/saiftynet/GLAM/blob/main/Examples/skeleton-GLAM.pl) to help get started

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


## The Program Flow
GLAM's operations are subject to change as it is new.
<ol type="1">
<li> When the GLAM object is created it generates a Canvas object which provides a window and graphics drawing primitives.</li>
<li> This Canvas Object is passed to the Game Object, along with any initialisation parameters</li>
<li> The Game object is initialised.  It stores the Game state, provides the game logic, has an update function that responds to any keys pressed, mouse state, and the time elapsed etc. at each Game loop.</li>
<li> When the GLAM's Game loop is started,

<ol type="a">
  <li>does some house keeping</li>
  <li>the loop checks for any end conditions</li>
  <li>submits the mouse,keyboard data to the Game Object's logic</li>
  <li>the Game object updates its statee, prepares the screen update before returning to the game loop</li>
  <li>loop the refreshes the screen buffer etc and continues</li>
  <li>if exit condition met GLAM tidies up and exits</li>
</ol></li>
</ol>

<img width="1129" height="663" alt="GLAM" src="https://github.com/user-attachments/assets/d8df1204-0170-468a-beb5-b650bb63c487" />

## OBJECTS

### GLAM::OpenGL and GLAM::SDL (maybe GLAM::Any)
### new


### SDLCanvas and GLCanvas

### Vector2

### Ball

### Logo

## TO DO

The objective is to add features as needed to create any new game.
2D games/tools are created first, and may in the future add more complex functionality.
But all times the objective will remain to produce near identical results whicher graphics back end is used.

## CHANGES
v0.03
* allow multiple ways of getting a Vector2 at inception
* correct for differences in coordinate geometry between OpenGL and SDL
* create an interactive Carrom like game
* Ball.pm has additional components for surface friction
* Acknowledge developers of perl OpenGL and perl SDL.

[Carrom-GLAM.webm](https://github.com/user-attachments/assets/ddc50613-1d68-4a95-9047-0a2ee01236b3)


v 0.02 Ball physics
* some additional Vector2 Methods
* (consider future overloading for Vector arithmetic)
* Added Ball.pm for initial ball physics in 2D
* Created Bounce-GLAM.pl to demo ball physics

[bounce-GLAM.webm](https://github.com/user-attachments/assets/6a65cee2-7671-48ad-89bd-af8eb5113c9e)


v 0.01  Initial Commit
* GLAM::SDL and GAM::OpenGL
* allows a Rope-GLAM.pl to work in both in OpenGL and SDL3



## Acknowledgements

* [phanthanhduy](https://github.com/foolish4)
* [Sanko Robinson](https://github.com/sanko)
* [Ed J](https://metacpan.org/dist/OpenGL-GLFW)
* [Chris Marshall](https://github.com/devel-chm)
