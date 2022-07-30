{
  lib,
  makeWrapper,
  nix-utils,
  runCommandLocal,
}:

let
  inherit (builtins)
    baseNameOf
    isList
  ;

  inherit (lib)
    escapeShellArg
    getExe
    mapAttrsToList
    optionalString
  ;

  inherit (lib.asserts)
    assertMsg
  ;

  inherit (nix-utils)
    unwords
  ;

  inherit (nix-utils.letterCase)
    camelToKebab
  ;
in

{
  wrapExecutable = {
    executable ? getExe targetPackage,
    targetPackage ? null,
    outPath ? "",
    name ? baseNameOf (if outPath != "" then outPath else executable),

    argv0 ? null,
    inheritArgv0 ? null,

    set ? null,
    setDefault ? null,
    unset ? null,

    chdir ? null,
    run ? null,

    addFlags ? null,
    appendFlags ? null,

    prefix ? null,
    suffix ? null,
    prefixEach ? null,
    suffixEach ? null,
    prefixContents ? null,
    suffixContents ? null,
  }@args:
  assert assertMsg (executable != null || targetPackage != null)
    "At least one of `executable` or `targetPackage` must be set.";
  let
    outPath' = "$out${optionalString (outPath != "") "/${outPath}"}";
    env = { nativeBuildInputs = [ makeWrapper ]; };
    args' = removeAttrs args [
      "executable"
      "name"
      "outPath"
      "targetPackage"
    ];

    format = {
      arg = name: value: "--${name} ${escapeShellArg value}";
      flag = name: enabled: optionalString enabled "--${name}";
      listOfArgs = name: values:
        if !isList values then format.arg name values else
        let
          args = map (value: "--${name} ${escapeShellArg value}") values;
        in
        unwords args;
      attrsOfArgs = argName: values:
        let
          formatArg = name: value:
            "--${argName} ${escapeShellArg name} ${escapeShellArg value}";
          args = mapAttrsToList formatArg values;
        in
        unwords args;
      listOfArgAttrs = indices: argName: argValues:
        let
          formatValues = values:
            let
              values' =
                mapAttrsToList (_: name: "${escapeShellArg values.${name}}") indices;
            in
            unwords values';
          args = map (values: "--${argName} ${formatValues values}") argValues;
        in
        unwords args;
    };

    argValueIndices = {
      prefix = {
        "1" = "env";
        "2" = "sep";
        "3" = "val";
      };

      prefixEach = {
        "1" = "env";
        "2" = "sep";
        "3" = "vals";
      };

      prefixContents = {
        "1" = "env";
        "2" = "sep";
        "3" = "files";
      };
    };

    formatArgs = with format; {
      argv0 = arg;
      inheritArgv0 = flag;

      set = attrsOfArgs;
      setDefault = attrsOfArgs;
      unset = listOfArgs;

      chdir = arg;
      run = listOfArgs;

      addFlags = arg;
      appendFlags = arg;

      prefix = listOfArgAttrs argValueIndices.prefix;
      suffix = listOfArgAttrs argValueIndices.prefix;
      prefixEach = listOfArgAttrs argValueIndices.prefixEach;
      suffixEach = listOfArgAttrs argValueIndices.prefixEach;
      prefixContents = listOfArgAttrs argValueIndices.prefixContents;
      suffixContents = listOfArgAttrs argValueIndices.prefixContents;
    };

    arguments = mapAttrsToList (name: value:
      optionalString (value != null) (formatArgs.${name} (camelToKebab name) value)
    ) args';
  in
  runCommandLocal name env ''
    mkdir --parents ${dirOf outPath'}
    makeWrapper ${executable} ${outPath'} ${toString arguments}
  '';
}
