{ pkgs, ... }: {
  imports = [ ../../../programs/nvim.nix ];

  home.packages = with pkgs; [
    lazygit
    httpie

    (python3.withPackages (ps: with ps; [
      numpy
      pandas
      scipy
      matplotlib
      pillow
      requests
      httpx
      pyserial
      pyvisa
      rich
      tqdm
      typer
      ipython
      pytest
      mypy
      python-dotenv
      loguru
      pydantic
      telethon
      cryptg
    ]))
    uv
    ruff
  ];
}
