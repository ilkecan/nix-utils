{ pkgs ? null, lib }@args:

let
  inherit (builtins)
    attrNames
    foldl'
    readDir
  ;

  inherit (lib)
    callPackageWith
    fix
    optional
    subtractLists
  ;

  callPackage = callPackageWith args;
  files = attrNames (readDir ./.);
  nonLibFiles = [
    "default.nix"
  ] ++ optional (pkgs == null) "pkgs";
  libFiles = subtractLists nonLibFiles files;
in
fix (self:
  let
    importLib = file:
      callPackage "${toString ./.}/${file}" {
        nix-utils = self;
      };
  in
  foldl' (l: r: l // r) {} (map importLib libFiles)
)
