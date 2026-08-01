{ pkgs, inputs, ... }:
let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.hostPlatform.system};
in {
  imports = [ inputs.spicetify-nix.homeManagerModules.default ];

  programs.spicetify = {
    enable = true;
    theme  = spicePkgs.themes.text;
    enabledCustomApps = with spicePkgs.apps; [
      lyricsPlus
    ];
    enabledExtensions = with spicePkgs.extensions; [
      fullAppDisplay
      popupLyrics
      shuffle
      powerBar
      seekSong
      playlistIcons
      fullAlbumDate
      skipStats
      songStats
      history
      betterGenres
      adblock
      volumePercentage
      beautifulLyrics
      simpleBeautifulLyrics
      aiBandBlocker
      madeForYouShortcut
    ];
  };
}
