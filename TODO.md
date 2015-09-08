* More complete testing

* Refactor Spec inspection methods into a Definition class, returned by
  `Spec#get_definition`. This way the Spec class will hold only the DSL.

* Create an Argument class to represent individual args, which has become more
  cumbersome with globs and default values.

* Change the Report class to raise an error when nonexistant argument or option
  names are given

* Better error handling; don't throw ruby exceptions at end-users.

* Raise an error when not all option-arguments without defaults are given

