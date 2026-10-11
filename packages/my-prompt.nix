{
  inputs,
  ...
}:

{
  imports = [ inputs.my-prompt.homeModules.default ];

  programs.my-prompt = {
    enable = true;
    enableFishIntegration = true;
  };
}
