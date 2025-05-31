if exists('g:loaded_claude')
    finish
endif
let g:loaded_claude = 1

" Initialize the plugin
lua require('claude').setup()
