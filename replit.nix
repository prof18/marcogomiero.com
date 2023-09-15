let
    pkgs2 = import (builtins.fetchTarball {
        url = "https://github.com/NixOS/nixpkgs/archive/refs/tags/22.11.tar.gz";
    }) {};
in

{ pkgs }: {
    deps = [
        pkgs2.hugo
		    pkgs2.miniserve
    ];
}