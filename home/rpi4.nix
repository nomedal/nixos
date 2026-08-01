{ nome, ... }: {
  imports = nome.lib.mkHome {
    context  = "server";
    identity = "private";
    sets     = [ "coding" ];
  };
}
