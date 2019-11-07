# Tools for hermetic working with the beancount program.

[Beancount](http://furius.ca/beancount/) is a textual double-entry accounting
software.  It is the best tool for the job.

Sadly it is very hard to produce and maintain the tool on a modern machine due to
its myriad Python dependencies.  A minimal installation of beancount is ~1GB,
which, relative to the program size, is enormous.

So I'm maintaining tools that package beancount and make it portable.  For
better or worse, this requires docker.
