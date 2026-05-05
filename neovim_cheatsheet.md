# Neovim Cheatsheet
# raghavpoonia/dotfiles — LazyVim
 
Space is the leader key. Press Space and wait — which-key shows all options.
 
 
## Modes
 
    i          insert mode
    Esc        back to normal mode
    v          visual mode (select text)
    V          visual line mode
    Ctrl+v     visual block mode
 
 
## File Explorer (neo-tree)
 
    Space e    toggle file explorer sidebar
    Space E    focus file explorer
 
Inside neo-tree:
    a          new file
    d          delete
    r          rename
    y          copy
    x          cut
    p          paste
    Enter      open file
    q          close
 
 
## Finding Things (Telescope)
 
    Space ff   find files in project
    Space fg   live grep — search text across all files
    Space fb   open buffers list
    Space fr   recent files
    Space fc   find in current file
    Space /    search in buffer
 
 
## File Navigation
 
    Space e    file explorer
    Ctrl+p     fuzzy find files (alternative)
    gd         go to definition
    gr         go to references
    K          hover docs for symbol under cursor
    [d         previous diagnostic
    ]d         next diagnostic
 
 
## Window + Split Management
 
    Space |    vertical split
    Space -    horizontal split
    Ctrl+h     move to left split
    Ctrl+j     move to lower split
    Ctrl+k     move to upper split
    Ctrl+l     move to right split
    Space wd   close split
 
 
## Buffers (open files)
 
    Space bb   switch buffer
    Space bd   close buffer
    ]b         next buffer
    [b         previous buffer
    Space bp   pin buffer
 
 
## Git (gitsigns + lazygit)
 
    Space gs   git status
    Space gg   open lazygit (if installed)
    Space gb   git blame line
    ]h         next git hunk
    [h         previous git hunk
    Space ghs  stage hunk
    Space ghr  reset hunk
 
 
## LSP (code intelligence)
 
    gd         go to definition
    gD         go to declaration
    gr         go to references
    gi         go to implementation
    K          hover documentation
    Space ca   code action
    Space cr   rename symbol
    Space cf   format file
    Space cd   show diagnostics
 
 
## Diagnostics + Trouble
 
    Space xx   toggle trouble panel (all errors)
    Space xw   workspace diagnostics
    Space xd   document diagnostics
 
 
## Terminal
 
    Ctrl+\     toggle floating terminal
    Space ft   terminal in new tab
 
 
## Search + Replace
 
    /word      search forward
    ?word      search backward
    n          next result
    N          previous result
    Esc        clear highlight
    Space sr   search and replace (spectre)
 
 
## Motions (vim core — practice these)
 
    w          next word
    b          previous word
    e          end of word
    0          start of line
    $          end of line
    gg         top of file
    G          bottom of file
    Ctrl+d     half page down
    Ctrl+u     half page up
    {          previous paragraph
    }          next paragraph
    %          matching bracket
 
 
## Copy + Paste
 
    yy         yank (copy) line
    dd         delete (cut) line
    p          paste below
    P          paste above
    y+motion   yank anything (yw = word, y$ = to end of line)
 
 
## Useful Combos
 
    ci"        change inside quotes
    di(        delete inside parentheses
    va{        select including braces
    =G         auto-indent from cursor to end of file
    gg=G       auto-indent entire file
 
 
## Outside Neovim
 
    bat file.py          syntax highlighted file view
    glow README.md       rendered markdown in terminal
    nvim .               open current directory as project
    nvim +telescope      open nvim straight into file finder
 
