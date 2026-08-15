# GLAM
Graphics Layer Abstraction Module

## SYNOPSIS
```
    use GLAM::OpenGL;
    # use GLAM::SDL;
    my $gl =new GLAM({height=>$WINDOW_HEIGHT,width=>$WINDOW_WIDTH,dt=>$DELTA_TIME_SEC});

```

## Description

Using interactive graphics typically requires a *Graphics Library*, which provides an API to connect
both user input to the display output.  SDL3 and OpenGL are available to Perl, and have their own Modules
on CPAN.  GLAM attempts to deliver a unified API with common functions e.g. drawing primitives and user input
identical whichever GL is used.
