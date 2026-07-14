{ pkgs, ... }:
{
  xdg.configFile."nvim/queries/scala/indents.scm".text = ''
    ; scala は upstream の nvim-treesitter query に indents.scm が無いため、
    ; 最低限のノードベースインデントをローカル override で提供する。
    [
      (template_body)
      (block)
    ] @indent.begin

    [
      "}"
      ")"
      "]"
    ] @indent.branch

    [
      "}"
      ")"
      "]"
    ] @indent.end
  '';

  programs.nixvim = {
    extraPlugins = with pkgs.vimPlugins; [
      nvim-metals
    ];
    extraPackages = with pkgs; [
      metals
    ];

    extraConfigLua = ''
      -- nvim-metals で Scala / sbt / Java バッファに Metals をアタッチする。
      -- ただし Scala プロジェクトのマーカーが見つかる場合だけ有効化する。
      local metals_config = require("metals").bare_config()
      metals_config.capabilities = require("cmp_nvim_lsp").default_capabilities()
      -- nvim-metals の自動インストール経路ではなく、Nix 管理の Metals バイナリを使う。
      metals_config.settings = {
        metalsBinaryPath = "${pkgs.metals}/bin/metals",
      }
      local uv = vim.uv or vim.loop

      -- ファイル/ディレクトリの存在確認を薄く共通化する。
      local function path_exists(path, expected_type)
        local stat = uv.fs_stat(path)
        if stat == nil then
          return false
        end
        if expected_type == nil then
          return true
        end
        return stat.type == expected_type
      end

      -- バッファ位置から親ディレクトリへ遡り、Scala プロジェクトのルートを検出する。
      -- マーカーは build.sbt / .scala-build / project/ を採用する。
      local function find_scala_project_root(bufname)
        local dir = vim.fs.dirname(bufname)
        if dir == nil then
          return nil
        end

        while dir ~= nil do
          if path_exists(dir .. "/build.sbt", "file")
            or path_exists(dir .. "/.scala-build")
            or path_exists(dir .. "/project", "directory")
          then
            return dir
          end

          local parent = vim.fs.dirname(dir)
          if parent == nil or parent == dir then
            break
          end
          dir = parent
        end

        return nil
      end

      local nvim_metals_group = vim.api.nvim_create_augroup("nvim-metals", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        group = nvim_metals_group,
        pattern = { "scala", "sbt", "java" },
        callback = function()
          -- ファイル未保存バッファではルート判定できないため何もしない。
          local bufnr = vim.api.nvim_get_current_buf()
          local bufname = vim.api.nvim_buf_get_name(bufnr)
          if bufname == "" then
            return
          end

          -- Scala プロジェクト外のファイルでは原則 Metals を起動しない。
          -- ただし .sc(worksheet / scala-cli スクリプト)は単体でも LSP を動かしたいので、
          -- プロジェクトが見つからなければファイルのディレクトリをルートに standalone 起動する
          -- (単体 Scala ファイルの補完/診断は Metals が scala-cli 経由で処理する。scala-cli 導入済み)。
          -- 既定の Scala バージョンで動く。特定版が要る worksheet は先頭に `//> using scala "2.13.x"` 等を書く。
          local root_dir = find_scala_project_root(bufname)
          if root_dir == nil then
            if bufname:match("%.sc$") then
              root_dir = vim.fs.dirname(bufname)
            else
              return
            end
          end

          -- バッファごとに root_dir を固定した config を渡して attach する。
          local config = vim.deepcopy(metals_config)
          config.root_dir = root_dir
          require("metals").initialize_or_attach(config)
        end,
      })

      -- Scala で "case" / "=>" 入力時の自動再インデントを抑制する。
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "scala",
        callback = function()
          vim.cmd("setlocal indentkeys-==case")
          vim.cmd("setlocal indentkeys-=<>>")
        end,
      })
    '';
  };
}
