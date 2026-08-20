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

The rope demonstration that triggered this is the first program that uses GLAM.
A single line can be changed to `use` either `OpenGL` or `SDL`.  





## Acknowledgements

* [phanthanhduy](https://github.com/foolish4)
* [Sanko Robinson](https://github.com/sanko)
