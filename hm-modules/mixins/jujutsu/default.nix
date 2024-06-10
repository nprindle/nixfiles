{ pkgs, config, ... }:

{
  home.sessionVariables = {
    # FIXME: jujutsu now wants the config under `Library/Application Support`,
    # so notify it of the current config path while home-manager conforms.
    JJ_CONFIG = "${config.xdg.configHome}/jj/config.toml";
  };

  programs.jujutsu = {
    enable = true;

    settings = {
      user.name = "Nicole Wren";

      ui = {
        allow-filesets = true;
        pager = "less -RF";
        paginate = "auto";
        default-command = "worklog";
        diff-editor = ":builtin";
        diff.tool = "difftastic";
        merge-editor = "vimdiff";
      };

      merge-tools = {
        vimdiff = {
          program = "nvim";
          # similar to the default, but opens files in a different order to
          # preserve commands like `1do`.
          merge-args = [ "-d" "-M" "$left" "$base" "$right" "$output" "-c" "$wincmd w | wincmd J | set modifiable write" ];
          merge-tool-edits-conflict-markers = true;
        };

        difftastic = {
          program = "${pkgs.difftastic}/bin/difft";
          diff-args = [ "--color=always" "$left" "$right" ];
        };
      };

      revsets = {
        log = "@ | ancestors(immutable_heads().., 2) | heads(immutable_heads())";
      };

      aliases = {
        "worklog" = [ "log" "-r" "(trunk()..@):: | (trunk()..@)-" ];
      };

      revset-aliases = {
        # graph utilities
        "xor(x, y)" = "(x ~ y) | (y ~ x)"; # commits in either x or y, but not both
        "bases(x, y)" = "heads(::x & ::y)"; # latest base commit of both x and y
        "fork(x, y)" = "heads(::x & ::y)::(x | y)"; # the bases of x and y, along with the paths to x and y; bases(x, y) | lr(x, y)
        "lr(x, y)" = "(::x ~ ::y) | (::y ~ ::x)"; # lr(x, y) is what 'git log' calls x...y

        # work utilities
        "named()" = "::(branches() | remote_branches() | tags() | trunk() | @ | git_head())";
        "anon()" = "~named()";

        # commit info
        "user(x)" = "author(x) | committer(x)";
        "mine()" =
          let
            names = [
              "Nicole Wren"
              "Nicole Prindle"
            ];
            emails = [
              "nicole@wren.systems"
              "nprindle18@gmail.com"
              "wrenn@squareup.com"
              "nprindle@squareup.com"
            ];
            toAuthor = x: "author(exact:${builtins.toJSON x})";
          in
          builtins.concatStringsSep " | " (builtins.map toAuthor (emails ++ names));
      };

      template-aliases = { };

      git = {
        push-branch-prefix = "kanwren/push-";
      };
    };
  };
}
