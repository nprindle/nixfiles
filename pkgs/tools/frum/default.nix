{ system, openssl_3, readline, libyaml, zlib, pkg-config, fenix, naersk, frum-src, lib }:

let
  toolchain = fenix.packages.${system}.minimal.toolchain;
  naersk-lib = naersk.lib.${system}.override {
    cargo = toolchain;
    rustc = toolchain;
  };
in
naersk-lib.buildPackage {
  pname = "frum";
  src = frum-src;

  buildInputs = [ openssl_3.dev readline libyaml zlib ];
  nativeBuildInputs = [ pkg-config ];

  # install completions
  postInstall = ''
    mkdir -p "$out/share/bash-completion/completions"
    "$out/bin/frum" completions --shell=bash > "$out/share/bash-completion/completions/frum"

    mkdir -p "$out/share/zsh/site-functions"
    "$out/bin/frum" completions --shell=zsh > "$out/share/zsh/site-functions/_frum"

    mkdir -p "$out/share/fish/vendor_completions.d"
    "$out/bin/frum" completions --shell=fish > "$out/share/fish/vendor_completions.d/frum.fish"
  '';

  meta = with lib; {
    description = "A little bit fast and modern Ruby version manager written in Rust";
    homepage = "https://github.com/TaKO8Ki/frum";
    license = licenses.mit;
    platforms = platforms.unix;
  };
}

