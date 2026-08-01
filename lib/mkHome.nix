{ inputs }:
{ context ? "workstation"
, identity ? "private"
, sets ? []
}:
[
  ../home/profiles/base
  ../home/users/nome/preferences.nix
  ../home/users/nome/identities/${identity}.nix
  ../home/profiles/contexts/${context}
] ++ map (s: ../home/profiles/sets/${s}) sets
