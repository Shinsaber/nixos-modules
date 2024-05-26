{
  config = ''
    """""""""""""""""""""""""""""""""""""""""""""""""""
    " => Général
    """""""""""""""""""""""""""""""""""""""""""""""""""
    " Enable filetype plugin
    filetype plugin on
    filetype plugin indent on
    
    " With a map leader it's possible to do extra key combinations
    " like <leader>w saves the current file
    let mapleader = ","
    
    " :W sudo saves the file 
    " (useful for handling the permission-denied error)
    command W w !sudo tee % > /dev/null
    
    """""""""""""""""""""""""""""""""""""""""""""""""""
    " => User interface
    """""""""""""""""""""""""""""""""""""""""""""""""""
    
    " Show line number
    set number
    " Relative number
    set relativenumber
    
    " Show the current vim cmd while typing it
    set showcmd
    
    " Turn on the Wild menu
    set wildmenu
    
    " Ignore compiled files
    set wildignore=*.o,*~,*.pyc
    set wildignore+=.git\*,.hg\*,.svn\*
    
    " Don't limit line size
    set textwidth=0
    
    " Don't break the line if it's too long
    set nowrap
    
    colorscheme elflord
    
    " Go to previous opened line (now plugin)
    "if has("autocmd")
    "  au BufReadPost * if line("'\"") > 0 && line("'\"") <= line("$") | exe "normal! g`\"" | endif
    "endif
    
    set backupcopy=yes

    " Configure backspace so it acts as it should act
    set backspace=eol,start,indent
    set whichwrap+=<,>,h,l"

    " Show matching brackets when text indicator is over them
    set showmatch
    " How many tenths of a second to blink when matching brackets
    set mat=2

    """""""""""""""""""""""""""""""""""""""""""""""""""
    " => Searching
    """""""""""""""""""""""""""""""""""""""""""""""""""
    
    " Ignore case when searching
    set ignorecase
    
    " When searching try to be smart about cases
    set smartcase
    
    " Highlight search results
    set hlsearch
    
    " Makes search act like search in modern browsers
    set incsearch
    
    " Automaticaly create folds accordingly to the syntax
    "set foldmethod=syntax
    
    """""""""""""""""""""""""""""""""""""""""""""""""""
    " => Text, tab
    """""""""""""""""""""""""""""""""""""""""""""""""""
    
    " Enable syntax highlighting
    syntax enable

    " Set utf8 as standard encoding and en_US as the standard language
    set encoding=utf8

    " Use Unix as the standard file type
    set ffs=unix,dos,mac

    " show existing tab with 4 spaces width
    set tabstop=4
    set shiftround                  "Round spaces to nearest shiftwidth multiple
    set nojoinspaces                "Don't convert spaces to tabs
    " when indenting with '>', use 4 spaces width
    set shiftwidth=4
    " On pressing tab, insert 4 spaces
    set expandtab
    " Be smart when using tabs ;)
    set smarttab"
    
    " Spell Check
    map <silent> <F6> "<Esc>:setlocal spell! spelllang=en<CR>"
    map <silent> <F7> "<Esc>:setlocal spell! spelllang=fr<CR>"
    "map <silent> <F7> "<Esc>:silent setlocal spell! spelllang=en<CR>"
    "map <silent> <F6> "<Esc>:silent setlocal spell! spelllang=fr<CR>"

    """""""""""""""""""""""""""""""""""""""""""""""""""
    " => NERDTree config
    """""""""""""""""""""""""""""""""""""""""""""""""""
    " AutoOpen if noFiles
    "autocmd StdinReadPre * let s:std_in=1
    "autocmd VimEnter     * if  argc() == 0 && !exists("s:std_in") | NERDTree | endif
    " AutoOpen if dir in parameter
    "autocmd StdinReadPre * let s:std_in=1
    "autocmd VimEnter     * if  argc() == 1 && isdirectory(argv()[0]) && !exists("s:std_in") | exe 'NERDTree' argv()[0] | wincmd p | ene | exe 'cd '.argv()[0] | endif
    " Close if NerdTree windows last left open
    "autocmd bufenter     * if (winnr("$") == 1 && exists("b:NERDTree") && b:NERDTree.isTabTree()) | q | endif
    " Open/Close on F2
    map <silent> <F2> :NERDTreeToggle<CR>
    let NERDTreeShowHidden=1
    let NERDTreeQuitOnOpen=1

    """""""""""""""""""""""""""""""""""""""""""""""""""
    " => TagBar config
    """""""""""""""""""""""""""""""""""""""""""""""""""
    map <silent> <F3> :TagbarToggle<CR>
      let tagbar_autofocus=1
      let tagbar_autoclose=1

    """""""""""""""""""""""""""""""""""""""""""""""""""
    " => Buffergator config
    """""""""""""""""""""""""""""""""""""""""""""""""""
    map <silent> <F4> :BuffergatorTabsToggle<CR>

    """""""""""""""""""""""""""""""""""""""""""""""""""
    " => Easy-align config
    """""""""""""""""""""""""""""""""""""""""""""""""""
    map ga <Plug>(EasyAlign)

    """""""""""""""""""""""""""""""""""""""""""""""""""
    " => Indent guides config
    """""""""""""""""""""""""""""""""""""""""""""""""""
    let g:indent_guides_guide_size = 1
    let g:indent_guides_color_change_percent = 5
    let g:indent_guides_enable_on_vim_startup = 1

    """""""""""""""""""""""""""""""""""""""""""""""""""
    " => Markdown config
    """""""""""""""""""""""""""""""""""""""""""""""""""
    autocmd FileType markdown :packadd markdown-preview-nvim

    " set to 1, nvim will open the preview window after entering the markdown buffer
    " default: 0
    let g:mkdp_auto_start = 1
    
    " set to 1, the nvim will auto close current preview window when change
    " from markdown buffer to another buffer
    " default: 1
    let g:mkdp_auto_close = 1
    
    " set to 1, the vim will refresh markdown when save the buffer or
    " leave from insert mode, default 0 is auto refresh markdown as you edit or
    " move the cursor
    " default: 0
    let g:mkdp_refresh_slow = 1
    
    " set to 1, the MarkdownPreview command can be use for all files,
    " by default it can be use in markdown file
    " default: 0
    let g:mkdp_command_for_global = 0
    
    " set to 1, preview server available to others in your network
    " by default, the server listens on localhost (127.0.0.1)
    " default: 0
    let g:mkdp_open_to_the_world = 0
    
    " use custom IP to open preview page
    " useful when you work in remote vim and preview on local browser
    " more detail see: https://github.com/iamcco/markdown-preview.nvim/pull/9
    " default empty
    let g:mkdp_open_ip = ""
    
    " specify browser to open preview page
    " default: ""
    let g:mkdp_browser = ""
    
    " set to 1, echo preview page url in command line when open preview page
    " default is 0
    let g:mkdp_echo_preview_url = 1
    
    " a custom vim function name to open preview page
    " this function will receive url as param
    " default is empty
    let g:mkdp_browserfunc = "firefox -new-tab"
    
    " options for markdown render
    " mkit: markdown-it options for render
    " katex: katex options for math
    " uml: markdown-it-plantuml options
    " maid: mermaid options
    " disable_sync_scroll: if disable sync scroll, default 0
    " sync_scroll_type: 'middle', 'top' or 'relative', default value is 'middle'
    "   middle: mean the cursor position alway show at the middle of the preview page
    "   top: mean the vim top viewport alway show at the top of the preview page
    "   relative: mean the cursor position alway show at the relative positon of the preview page
    " hide_yaml_meta: if hide yaml metadata, default is 1
    " sequence_diagrams: js-sequence-diagrams options
    " content_editable: if enable content editable for preview page, default: v:false
    " disable_filename: if disable filename header for preview page, default: 0
    let g:mkdp_preview_options = {
        \ 'mkit': {},
        \ 'katex': {},
        \ 'uml': {},
        \ 'maid': {},
        \ 'disable_sync_scroll': 0,
        \ 'sync_scroll_type': 'middle',
        \ 'hide_yaml_meta': 1,
        \ 'sequence_diagrams': {},
        \ 'flowchart_diagrams': {},
        \ 'content_editable': v:false,
        \ 'disable_filename': 0
        \ }
    
    " use a custom markdown style must be absolute path
    " like '/Users/username/markdown.css' or expand('~/markdown.css')
    let g:mkdp_markdown_css = ""
    
    " use a custom highlight style must absolute path
    " like '/Users/username/highlight.css' or expand('~/highlight.css')
    let g:mkdp_highlight_css = ""
    
    " use a custom port to start server or random for empty
    let g:mkdp_port = ""
    
    " preview page title
    " $\{name} will be replace with the file name
    let g:mkdp_page_title = '「$\{name}」'
    
    " recognized filetypes
    " these filetypes will have MarkdownPreview... commands
    let g:mkdp_filetypes = ['markdown']
  '';
}
