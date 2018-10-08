Identicon
=========

[![example output](example.png)](example.png)

a cute little idea stolen from
[rbishop](https://github.com/rbishop/identicon/blob/master/lib/identicon.ex).
provides a function for generating an "identicon" (an icon produced from the
hash of a given string). please feel free to steal from me as well! ^_^

this version is a little cleaner and uses softer, "web-safe" foreground colours
on a customisable background.

compile in the usual manner:

	mix deps.get
	mix compile

and then if you just want to test it out (with your name or whatever XD), try
something like:

	iex -S mix
	iex(1)> File.write "Elixir.png", Identicon.gen("Elixir", {36, 32, 36})

which produces:

[![generated icon](Elixir.png)](Elixir.png)
