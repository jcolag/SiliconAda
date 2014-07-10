SiliconAda
==========

SiliconAda is a Ada-to-VHDL compiler.  It attempts to analyze dependencies between lines of code in order to maximize parallelism in the output code.

I wrote it as part of my Master's thesis, a million years ago.  I will try to release that, as well, on the chance it contains anything of use.

Build
-----

Assuming you have *flex* and *byacc* installed, just type `make`.

If you prefer a different lexical analyzer and parser generator, they should mostly work if you tweak the variables at the top of `Makefile`.

Run
---

Believe it or not, there are no command-line parameters, here.  It reads Ada code from `stdin` and dumps VHDL to `stdout`.  For example:

    sa < input.ada > output.vhdl

More or less...

Warning
-------

Oh, dear!

I wrote this a long time ago as a student.  I remember being in a rather extreme rush.  I remember not knowing exactly how seriously I should take the project.

That said, I clearly remember testing it and getting decent results, whereas this code appears to fail rather spectacularly for no good reason.  Maybe what I found on the dusty hard drive is an older version of the code, before I released it.  Or maybe I was extremely careful with my testing.

In either case, "fragile" doesn't begin to describe this.  Use it at your own risk, for now.  I'll be looking into it as time permits, in hopes of rehabilitating it.  If anybody has any thoughts, I'd be happy to hear them.

Unlike some of my projects, after all, this might actually be useful to somebody, somewhere.  So, if I'm going to make sure the code for [Thue](https://github.com/jcolag/Thue) is readable, the least I can do is get this running again.

It might be smart to edge away from Ada, too.

As an extra-special warning, I don't recall if I ever got access to a VHDL compiler.  So, while the VHDL output I've seen *looks* about right, it probably hasn't been rigorously tested.

Still, since it might be useful to anybody working with FPGAs, I believe it's worth releasing, even in this terrible condition.
