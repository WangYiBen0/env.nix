{ pkgsFor, forAllSystems, ... }:

forAllSystems (system: (pkgsFor system).nixfmt)
