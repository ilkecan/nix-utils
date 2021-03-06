{ lib, nix-utils }:

let
  inherit (lib)
    importTOML
  ;

  inherit (nix-utils)
    mapListToAttrs
  ;
in

{
  importCargoLock = directory:
    let
      cargoLock = importTOML "${toString directory}/Cargo.lock";
    in
    mapListToAttrs (p: { name = p.name; value = p; }) cargoLock.package;

  importCargoToml = directory:
    importTOML "${toString directory}/Cargo.toml";
}
