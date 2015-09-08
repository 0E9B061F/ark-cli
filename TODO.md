* More complete testing

* Default values for options

* Refactor Spec inspection methods into a Definition class, returned by
  `Spec#get_definition`. This way the Spec class will hold only the DSL.

* Option and argument names should be stored as string internally. Methods which
  access options and arguments should accept symbol or strings. Currently we
  have an ad-hoc mixture of both.

* Make sure the globbed argument value is always an Array, even when the glob
  receieves no args (currently nil if no arg is given)

* Create an Argument class to represent individual args, which has become more
  cumbersome with globs and default values.

* Make sure an error is raised when not all required arguments are given

* Make sure an error is raised when `Spec#raise_on_trailing` is specified and
  trailing arguments are given

* Change the Report class to raise an error when nonexistant argument or option
  names are given

* Better error handling; don't throw ruby exceptions at end-users.

