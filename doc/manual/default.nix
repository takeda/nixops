{ revision ? "local", nixpkgs ? <nixpkgs> }:

let

  pkgs = import nixpkgs {};

  systemModule = pkgs.lib.fixMergeModules [ ../../nix/options.nix ./dummy.nix ] {
                   inherit pkgs; utils = {};
                   resources = { gceImages.bootstrap = {}; };
                   name = "<name>"; uuid = "<uuid>";
                 };

  options = pkgs.lib.filter (opt: opt.visible && !opt.internal)
    (pkgs.lib.optionAttrSetToDocList systemModule.options);

  backwardsCompat = { options }: let
    optionsXML = builtins.toFile "options.xml" (builtins.unsafeDiscardStringContext
      (builtins.toXML options));
  in {
    optionsDocBook = pkgs.runCommand "options-db.xml" {} ''
      ${pkgs.libxslt.bin or pkgs.libxslt}/bin/xsltproc \
        --stringparam revision '${revision}' \
        --stringparam program 'nixops' \
        -o intermediate.xml ${nixpkgs + "/nixos/doc/manual/options-to-docbook.xsl"} ${optionsXML}
      ${pkgs.libxslt.bin or pkgs.libxslt}/bin/xsltproc \
        -o $out ${nixpkgs + "/nixos/doc/manual/postprocess-option-descriptions.xsl"} intermediate.xml
  ''; };


in (pkgs.nixosOptionsDoc or backwardsCompat) {
  inherit options;
}
