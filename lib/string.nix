_lib: {
  lastAfterDash =
    s:
    let
      match = builtins.match ".*-(.*)" s;
    in
    if match == null then s else builtins.head match;
}
