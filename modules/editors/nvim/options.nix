{ ... }:
{
  programs.nixvim.opts = {
    # 普段の編集で欲しい最低限の見た目。
    number = true;
    relativenumber = true;
    signcolumn = "yes"; # 行番号の左側に、LSPの警告やGitの変更印を出す隙間を常に確保
    winbar = "%f %m"; # 各ウィンドウ上部にファイル名と変更有無を表示
    wrap = true;
    scrolloff = 8; # カーソル移動時、画面の上下に常に8行確保
    termguicolors = true; # 24bit フルカラーを有効

    # インデントは 2 スペースに統一。
    expandtab = true;
    shiftwidth = 2;
    tabstop = 2;
    autoindent = true;
    smartindent = true;

    # 検索は普段は大文字小文字を無視しつつ、大文字を含めたら厳密一致。
    ignorecase = true;
    smartcase = true;
    hlsearch = false;

    # 余計な一時ファイルは作らず、undo だけは残す。
    swapfile = false;
    backup = false;
    undofile = true;

    # 使い勝手のための小さな調整。
    splitright = true;
    splitbelow = true;
    mouse = "a";
    clipboard = "unnamedplus";
    timeoutlen = 800;
    updatetime = 200;
  };
}
