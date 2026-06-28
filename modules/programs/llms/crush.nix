{ inputs, ... }:

{
  imports = [
    inputs.charmbracelet.homeModules.crush
  ];

  programs.crush = {
    enable = true;
    settings = {
      options = {
        attribution.generated_with = false;
        auto_lsp = true;
        tui = {
          compact_mode = true;
          transparent = true;
        };
      };
    };
  };
}
