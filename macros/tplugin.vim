" tplugin.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @Website:     http://www.vim.org/account/profile.php?user_id=4037
" @GIT:         http://github.com/tomtom/tplugin_vim/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-01-04.
" @Last Change: 2012-02-23.
" @Revision:    1950
" GetLatestVimScripts: 2917 1 :AutoInstall: tplugin.vim

if &cp || exists("loaded_tplugin")
    finish
endif
let loaded_tplugin = 14

let s:save_cpo = &cpo
set cpo&vim


if !exists('g:tplugin_autoload')
    " Enable autoloading. See |:TPluginScan|, |:TPluginCommand|, and 
    " |:TPluginFunction|.
    " Values:
    "   1 ... Enable autoload (default)
    "   2 ... Enable autoload and automatically run |:TPluginScan| 
    "         after updating tplugin.
    let g:tplugin_autoload = 1   "{{{2
endif


if !exists('g:tplugin_menu_prefix')
    " If autoload is enabled and this variable is non-empty, build a 
    " menu with available plugins.
    " Menus are disabled by default because they are less useful 
    " than one might think with autoload enabled.
    " A good choice for this variable would be, e.g., 
    " 'Plugin.T&Plugin.'.
    " NOTE: You have to re-run |:TPluginScan| after setting this 
    " value.
    let g:tplugin_menu_prefix = ''   "{{{2
    " let g:tplugin_menu_prefix = 'Plugin.T&Plugin.'   "{{{2
endif


if !exists('g:tplugin_file')
    " The prefix for tplugin control files.
    let g:tplugin_file = '_tplugin'   "{{{2
endif


if !exists('g:tplugin_load_plugin')
    " A list of pairs [REGEXP, VALUE] that determine how tplugin handles 
    " autoload function calls and filetype plugins.
    "
    " When an autoload function or filetype plugin is loaded, the 
    " respective plugin is added to 'runtimepath'. This variable decides 
    " whether the corresponding plugin should be loaded too. Possible 
    " values are:
    "
    "   . :: Don't load any plugins
    "   * :: Load all plugins (default if no REGEXP pattern matches the 
    "        full repo directory name)
    let g:tplugin_load_plugin = []   "{{{2
endif


" :display: :TPlugin[!] REPOSITORY [PLUGINS ...]
" Register certain plugins for being sourced at |VimEnter| time.
" See |tplugin.txt| for details.
"
" With the optional '!', the plugin will be loaded immediately.
" In interactive use, i.e. once vim was loaded, plugins will be loaded 
" immediately anyway.

" IF REPOSITORY contains a slash or a backslash, it is considered the 
" path relative from the current root directory to the plugin directory. 
" This allows you to deal with repositories with a non-standard 
" directory layout. Otherwise it is assumed that the source files are 
" located in the "plugin" subdirectory.
"
" IF PLUGIN is "-", the REPOSITORY will be enabled but no plugin will be 
" loaded.
command! -bang -nargs=+ -complete=customlist,s:TPluginComplete TPlugin
            \ call TPluginRequire(!empty("<bang>"), '', <f-args>)


" :display: :TPluginRoot[!] DIRECTORY
" Define the root directory for the following |:TPlugin| commands.
" Read autoload information if available (see |g:tplugin_autoload| and 
" |:TPluginScan|).
"
" With the optional <bang>, don't register commands, functions etc. when 
" scanning the root with |:TPluginScan|.
"
" If DIRECTORY ends with "*", it doesn't refer to a directory hierarchy 
" à la vimfiles but to a single "flat" directory.
"
" If tplugin was installed a directory called .vim or vimfiles, the 
" default root directory is the "bundle" subdirectory of the first 
" element in 'runtimepath'. Otherwise, the default root directory is the 
" directory where tplugin_vim was installed in, i.e. this assumes that 
" tplugin was loaded from ROOT/tplugin_vim/macros/tplugin.vim
"
" Example: >
"   " A collection of git repositories
"   TPluginRoot ~/src/git_repos
"   " A directory with experimental plugins
"   TPluginRoot ~/vimfiles/experimental_plugins/*
command! -bang -nargs=+ -complete=dir TPluginRoot
            \ call s:SetRoot(<q-args>, !empty("<bang>"))


" :display: :TPluginScan[!] [WHAT] [ROOT]
" Scan the current root directory for commands and functions. Save 
" autoload information in "ROOT/_tplugin.vim".
"
" Where WHAT is a set of letters determining the information being 
" collected. See |g:tplugin#scan| for details.
"
" With the optional '!', the autocommands are immediatly usable.
"
" Other than the AsNeeded plugin, tplugin doesn't support the creation 
" of autoload information for maps.
"
" If you collect repositories in one than more directory, I'd suggest to 
" create a special script.
"
" The source file may contain special markers that make :TPluginScan 
" include text in the _tplugin.vim file:
"                                                     *@TPluginInclude*
" Blocks of non-empty lines are introduced with an @TPluginInclude tag: >
"
"   " @TPluginInclude
"   augroup Foo
"        autocmd!
"        autocmd Filetype foo call foo#Init()
"   augroup END
"
" Special lines are prefixed with @TPluginInclude: >
"   
"   " @TPluginInclude if !exists('g:foo') | let g:foo = 1 | endif
"
" Example: >
"   TPluginRoot dir1
"   TPluginScan
"   TPluginRoot dir2
"   TPluginScan
command! -bang -nargs=* TPluginScan
            \ call tplugin#ScanRoots(!empty("<bang>"), s:roots, s:shallow_roots, [<f-args>])


" :display: :TPluginBefore FILE_RX COMMAND
" |:execute| COMMAND after loading a file matching the |regexp| pattern 
" FILE_RX. The COMMAND is executed after the repo's path is added to the 
" 'runtimepath'.
"
" This command should be best put into ROOT/tplugin_REPO.vim files, 
" which are loaded when enabling a source repository.
"
" Example: >
"   " Load master.vim before loading any plugin in a repo
"   TPluginBefore plugin/.\{-}\.vim runtime! macros/master.vim
"
" It can also be included in the comments of source files (you have 
" to prepend it with a "@"): >
"   "@TPluginBefore my_repo/autoload DoThis
"   let loaded_yup = 1
command! -nargs=+ TPluginBefore
            \ call s:AddHook(s:before, [<f-args>][0], join([<f-args>][1:-1]))


" :display: :TPluginAfter FILE_RX COMMAND
" |:execute| COMMAND after loading a file matching the |regexp| pattern 
" FILE_RX.
" See also |:TPluginBefore|.
command! -nargs=+ TPluginAfter
            \ call s:AddHook(s:after, [<f-args>][0], join([<f-args>][1:-1]))


" :display: TPluginUpdate[!]
" Update all repos (VCS types only).
" Requires compiled-in ruby support and http://github.com/tomtom/vcsdo 
" to be installed. You also have to set |g:tplugin#vcsdo#script|.
"
" With the optional !, show which commands would be issued but don't do 
" anything.
command! -bang TPluginUpdate call tplugin#vcsdo#Update(!empty('<bang>'), s:roots)


let &rtp .= ','. escape(expand('<sfile>:p:h:h'), ',')
let s:roots = []
let s:shallow_roots = []
let s:rtp = split(&rtp, ',')
let s:reg = {}
let s:repos = {}
let s:plugins = {}
let s:done = {'-': {}}
let s:before = {}
let s:after = {}
let s:dependencies = {}
let s:ftypes = {}
let s:functions = {}
let s:autoloads = {}
let s:maps = {}
let s:command_nobang = {}


" :nodoc:
function! TPluginFileJoin(...) "{{{3
    let parts = map(copy(a:000), 'substitute(v:val, ''[\/]\+$'', "", "")')
    return join(parts, '/')
endf


if exists('*fnameescape')
    " :nodoc:
    function! TPluginFnameEscape(filename) "{{{3
        return fnameescape(a:filename)
    endf
else
    " :nodoc:
    function! TPluginFnameEscape(filename) "{{{3
        let cs = " \t\n*?[{`$\\%#'\"|!<"
        return escape(a:filename, cs)
    endf
endif


" :nodoc:
function! TPluginStrip(string) "{{{3
    let string = substitute(a:string, '^\s\+', '', '')
    let string = substitute(string, '\s\+$', '', '')
    return string
endf


function! s:CommandKey(pluginfile) "{{{3
    return substitute(a:pluginfile, '\\', '/', 'g')
endf


function! s:DefineCommand(def1) "{{{3
    let [cmd0; file] = a:def1
    let string = TPluginStrip(cmd0)
    if match(string, '\s') == -1
        return 'command! -bang -range -nargs=* '. string
    else
        " let cmd = matchstr(a:string, '\s\zs\u\w*$')
        if string =~ '^com\%[mand]\zs\s'
            let pluginfile = s:GetPluginFile(s:GetRoot(), file[0], file[1])
            let pluginkey = s:CommandKey(pluginfile)
            if !has_key(s:command_nobang, pluginkey)
                let s:command_nobang[pluginkey] = {}
            endif
            let cmd = s:ExtractCommand(cmd0)
            if !has_key(s:command_nobang[pluginkey], cmd)
                let s:command_nobang[pluginkey][cmd] = 1
            endif
            let string = substitute(string, '^com\%[mand]\zs\s', '! ', '')
        endif
        return string
    endif
endf


function! s:ExtractCommand(cmd0) "{{{3
    return matchstr(a:cmd0, '\s\zs\u\w*$')
endf


" args: A string if type == 1, a list if type == 2
function! s:Autoload(type, def, bang, range, args) "{{{3
    let [root, cmd0; file] = a:def
    let cmd0 = TPluginStrip(cmd0)
    if match(cmd0, '\s') != -1
        let cmd = s:ExtractCommand(cmd0)
    else
        let cmd = cmd0
    endif
    if a:type == 1 " Command
        let pluginfile = s:GetPluginFile(root, file[0], file[1])
        call s:RemoveAutoloads(pluginfile, [cmd])
    endif
    " echom "DBG s:Autoload" string(file)
    if len(file) >= 1 && len(file) <= 2
        call call('TPluginRequire', [1, root] + file)
    else
        echoerr 'Malformed autocommand definition: '. join(a:def)
    endif
    if a:type == 1 " Command
        let range = join(filter(copy(a:range), '!empty(v:val)'), ',')
        try
            exec range . cmd . a:bang .' '. a:args
        catch /^Vim\%((\a\+)\)\=:E481/
            exec cmd . a:bang .' '. a:args
        catch
            echohl Error
            echom v:errmsg
            echohl NONE
        endtry
    elseif a:type == 2 " Function
    elseif a:type == 3 " Map
    else
        echoerr 'Unsupported type: '. a:type
    endif
endf


" :nodoc:
function! TPluginFiletype(filetype, repos) "{{{3
    if !has_key(s:ftypes, a:filetype)
        let s:ftypes[a:filetype] = []
    endif
    let rootrepos = map(copy(a:repos), 's:GetRoot() ."/". v:val')
    call extend(s:ftypes[a:filetype], rootrepos)
endf


function! s:LoadFiletype(filetype) "{{{3
    let rootrepos = remove(s:ftypes, a:filetype)
    for rootrepo in rootrepos
        call TPluginRequire(1, rootrepo, '.', s:GetPluginPattern(rootrepo))
    endfor
    exec 'setfiletype '. a:filetype
endf


function! s:AutoloadFunction(fn) "{{{3
    " echom "DBG AutoloadFunction" a:fn has_key(s:functions, a:fn)
    if stridx(a:fn, '#') != -1
        let prefix = substitute(a:fn, '#[^#]\{-}$', '', '')
        " echom "DBG AutoloadFunction prefix" prefix has_key(s:autoloads, prefix)
        if has_key(s:autoloads, prefix)
            let def = remove(s:autoloads, prefix)
            let root = def[0]
            let repo = def[1]
            let [root, rootrepo, plugindir] = s:GetRootPluginDir(root, repo)
            call TPluginRequire(1, root, repo, s:GetPluginPattern(rootrepo))
            call s:RunHooks(s:before, rootrepo, rootrepo .'/autoload/')
            let autoload_file = 'autoload/'. substitute(prefix, '#', '/', 'g') .'.vim'
            " echom "DBG AutoloadFunction autoload_file" rootrepo autoload_file
            exec printf('autocmd TPlugin SourceCmd */%s call s:SourceAutoloadFunction(%s, %s)',
                        \ escape(autoload_file, '\ '), string(rootrepo), string(autoload_file))
        endif
    endif
    if has_key(s:functions, a:fn)
        let def = s:functions[a:fn]
        call s:Autoload(2, def, '', [], [])
    endif
endf


function! s:GetPluginPattern(rootrepo) "{{{3
    " TLogVAR a:rootrepo
    for [rx, val] in g:tplugin_load_plugin
        if a:rootrepo =~ rx
            return val
        endif
    endfor
    return '*'
endf


function! s:SourceAutoloadFunction(rootrepo, autoload_file) "{{{3
    let afile = expand('<afile>')
    " echom "DBG SourceAutoloadFunction" afile
    let afile = TPluginGetCanonicalFilename(strpart(afile, len(afile) - len(a:autoload_file)))
    if afile == a:autoload_file
        let autoload_file_e = TPluginFnameEscape(a:autoload_file)
        exec printf('autocmd! TPlugin SourceCmd %s', escape(a:autoload_file, '\ '))
        exec 'runtime! '. autoload_file_e
        exec 'runtime! after/'. autoload_file_e
        call s:RunHooks(s:after, a:rootrepo, a:rootrepo .'/autoload/')
    endif
endf


" :display: TPluginMap(map, repo, plugin, ?remap="")
" MAP is a map command and the map. REPO and PLUGIN are the same as for 
" the |:TPlugin| command.
"
" Examples: >
"   " Map for <plug>Foo:
"   call TPluginMap('map <plug>Foo', 'mylib', 'myplugin')
"
"   " Load the plugin when pressing <f3> and remap the key to an appropriate 
"   " command from the autoloaded plugin:
"   call TPluginMap('map <f3>', 'mylib', 'myplugin', ':Foo<cr>')
function! TPluginMap(map, repo, plugin, ...) "{{{3
    if g:tplugin_autoload
        let remap = a:0 >= 1 ? a:1 : ''
        if has_key(s:plugins, a:plugin)
            let repo = s:plugins[a:plugin]
            if repo == a:repo
                let root = s:repos[repo]
            else
                let root = s:GetRoot()
            endif
        else
            let root = s:GetRoot()
        endif
        let def   = [root, a:repo, a:plugin]
        let keys  = s:MapKeys(a:map)
        if empty(keys)
            let keys = matchstr(a:map, '\S\+$')
        endif
        if !empty(keys)
            let pluginfile = s:GetPluginFile(s:GetRoot(), a:repo, a:plugin)
            if !has_key(s:maps, pluginfile)
                let s:maps[pluginfile] = {}
            endif
            let s:maps[pluginfile][keys] = a:map
            let mode = s:MapMode(a:map)
            try
                let maparg = maparg(keys, mode)
            catch
                let maparg = ""
            endtry
            if empty(maparg)
                let map = substitute(a:map, '<script>', '', '')
                let [pre, post] = s:GetMapPrePost(a:map)
                let args = join([string(keys), string(a:map), string(remap), string(def)], ',')
                let args = substitute(args, '<', '<lt>', 'g')
                let map .= ' '. pre . ':call <SID>Remap('. args .')<cr>' . post
                exec map
            endif
        endif
    endif
endf


function! s:GetMapPrePost(map) "{{{3
    let mode = matchstr(a:map, '\([incvoslx]\?\)\ze\(nore\)\?map')
    if mode ==# 'n'
        let pre  = ''
        let post = ''
    elseif mode ==# 'i'
        let pre = '<c-\><c-o>'
        let post = ''
    elseif mode ==# 'v' || mode ==# 'x'
        let pre = '<c-c>'
        let post = '<C-\><C-G>'
    elseif mode ==# 'c'
        let pre = '<c-c>'
        let post = '<C-\><C-G>'
    elseif mode ==# 'o'
        let pre = '<c-c>'
        let post = '<C-\><C-G>'
    else
        let pre  = ''
        let post = ''
    endif
    return [pre, post]
endf


function! s:MapKeys(map) "{{{3
    return matchstr(a:map, '\c<plug>\w\+$')
endf


function! s:Unmap(map, keys) "{{{3
    let mode = s:MapMode(a:map)
    exec 'silent! '. mode .'unmap '. a:keys
endf


function! s:Remap(keys, map, remap, def) "{{{3
    call s:Unmap(a:map, a:keys)
    call call('TPluginRequire', [1] + a:def)
    if !empty(a:remap)
        exec a:map .' '. a:remap
    endif
    let keys = substitute(a:keys, '<\ze\w\+\(-\w\+\)*>', '\\<', 'g')
    let keys = eval('"'. escape(keys, '"') .'"')
    call feedkeys(keys, 't')
    return keys
endf


function! s:MapMode(map) "{{{3
    return matchstr(a:map, '\<\([incvoslx]\?\)\ze\(nore\)\?map')
endf


function! s:GetRoot() "{{{3
    return s:roots[0]
endf


function! s:GetRootFromRootrepo(rootrepo) "{{{3
    let root = ''
    for r in s:roots
        let rl = len(r)
        if r == strpart(a:rootrepo, 0, rl) && rl > len(root)
            let root = r
        endif
    endfor
    return r
endf


" :nodoc:
function! TPluginAutoload(prefix, def) "{{{3
    let s:autoloads[a:prefix] = [s:GetRoot()] + a:def
endf


" :nodoc:
function! TPluginRegisterRepo(repo) "{{{3
    let s:repos[a:repo] = s:GetRoot()
endf


" :nodoc:
function! TPluginRegisterPlugin(repo, plugin) "{{{3
    let s:plugins[a:plugin] = a:repo
endf


" :nodoc:
function! TPluginMenu(item, ...) "{{{3
    if !empty(g:tplugin_menu_prefix)
        let def = [2, s:GetRoot()] + a:000
        call map(def, 'string(v:val)')
        exec 'amenu <silent> '. g:tplugin_menu_prefix . a:item .' :call TPluginRequire('. join(def, ', ') .')<cr>'
    endif
endf


" :nodoc:
function! TPluginGetCanonicalFilename(filename) "{{{3
    let filename = substitute(a:filename, '[\\/]\+$', '', '')
    let filename = substitute(filename, '\\', '/', 'g')
    return filename
endf


" :nodoc:
" Remove any "/*" suffix.
function! TPluginGetRootDirOnDisk(dir) "{{{3
    let dir = TPluginGetCanonicalFilename(a:dir)
    let dir = substitute(dir, '[\\/]\*$', '', '')
    let dir = substitute(dir, '[\\/]\+$', '', '')
    return dir
endf


let s:rescanned_roots = 0

" function! s:SetRoot(dir, ?shallow=0)
function! s:SetRoot(dir, ...) "{{{3
    " echom "DBG SetRoot" a:dir
    let shallow = a:0 >= 1 ? a:1 : 0
    let root = TPluginGetCanonicalFilename(fnamemodify(a:dir, ':p'))
    let idx = index(s:roots, root)
    if idx > 0
        call remove(s:roots, idx)
    endif
    if idx != 0
        call insert(s:roots, root)
    endif
    if shallow
        call insert(s:shallow_roots, root)
    endif
    " Don't reload the file. Old autoload definitions won't be 
    " overwritten anyway.
    if idx == -1 && g:tplugin_autoload
        " if s:IsFlatRoot(root)
        "     call add(g:tplugin_load_plugin, ['\V'. escape(root, '\') .'\>\(\[\/]\|\$\)', '.'])
        " endif
        let rootdir = TPluginGetRootDirOnDisk(root)
        let autoload = TPluginFileJoin(rootdir, g:tplugin_file .'.vim')
        if filereadable(autoload)
            try
                exec 'source '. TPluginFnameEscape(autoload)
            catch /^TPluginScan:Outdated$/
                if !s:rescanned_roots
                    autocmd VimEnter *
                                \ echohl WarningMsg | 
                                \ echom "TPlugin: Outdated _tplugin.vim files ... Rescanning roots: Please be patient" |
                                \ echohl NONE
                    autocmd VimEnter * call tplugin#ScanRoots(1, s:roots, s:shallow_roots, [])
                    let s:rescanned_roots = 1
                endif
            catch
                echohl Error
                echom v:exception
                echom "Maybe the problem can be solved by running :TPluginScan"
                echohl NONE
            endtry
        endif
    endif
endf


function! s:AddRepo(rootrepos, isflat) "{{{3
    let rootrepos = filter(copy(a:rootrepos), '!has_key(s:done, v:val)')
    if !empty(rootrepos)
        for rootrepo in rootrepos
            let s:done[rootrepo] = {}
            let rtp = split(&rtp, ',')
            let idx = index(rtp, s:rtp[0])
            if idx == -1
                let idx = 1
            else
                let idx += 1
            endif
            " echom "DBG AddRepo alter rtp:" string(rtp) idx
            if index(rtp, rootrepo) == -1
                if !a:isflat
                    " echom "DBG AddRepo rootrepo:" rootrepo idx
                    let rtp = insert(rtp, rootrepo, idx)
                    let after_dir = TPluginFileJoin(rootrepo, 'after')
                    if isdirectory(after_dir)
                        let rtp = insert(rtp, after_dir, -1)
                    endif
                    let &rtp = join(rtp, ',')
                    " echom "DBG AddRepo neuer &rtp:" &rtp
                    let repo_tplugin = rootrepo .'/'. g:tplugin_file .'.vim'
                    if filereadable(repo_tplugin)
                        exec 'source '. TPluginFnameEscape(repo_tplugin)
                    endif
                    let repo = fnamemodify(rootrepo, ':t')
                    if has_key(s:dependencies, repo)
                        let deps = s:dependencies[repo]
                        call remove(s:dependencies, repo)
                        for dependency in deps
                            " echom "DBG dependency" repo dependency
                            call TPluginRequire(1, '', dependency)
                        endfor
                    endif
                endif
                let tplugin_repo = fnamemodify(rootrepo, ':h') .'/'. g:tplugin_file .'_'. fnamemodify(rootrepo, ':t') .'.vim'
                if filereadable(tplugin_repo)
                    exec 'source '. TPluginFnameEscape(tplugin_repo)
                endif
            endif
        endfor
    endif
endf


function! s:LoadPlugins(mode, rootrepo, pluginfiles) "{{{3
    if empty(a:pluginfiles)
        return
    endif
    let done_repo = s:done[a:rootrepo]
    if has_key(done_repo, '*')
        return
    endif
    for pluginfile in a:pluginfiles
        let pluginfile = TPluginGetCanonicalFilename(pluginfile)
        " echom "DBG LoadPlugins" pluginfile
        if pluginfile != '-' && !has_key(done_repo, pluginfile)
            let done_repo[pluginfile] = 1
            if filereadable(pluginfile)
                call s:LoadFile(a:rootrepo, pluginfile)
                if a:mode == 2
                    echom "TPlugin: Loaded ". pathshorten(pluginfile)
                endif
            endif
        endif
    endfor
endf


function! s:LoadFile(rootrepo, filename) "{{{3
    let pos0 = len(a:rootrepo) + 1
    call s:RemoveAutoloads(a:filename, [])
    call s:RunHooks(s:before, a:rootrepo, a:filename)
    " exec 'source '. TPluginFnameEscape(a:filename)
    " exec 'runtime! after/'. TPluginFnameEscape(strpart(a:filename, pos0))
    exec 'runtime! '. TPluginFnameEscape(strpart(a:filename, pos0))
    call s:RunHooks(s:after, a:rootrepo, a:filename)
endf


function! s:AddHook(hooks, key, value) "{{{3
    if has_key(a:hooks, a:key)
        call add(a:hooks[a:key], a:value)
    else
        let a:hooks[a:key] = [a:value]
    endif
endf


function! s:RunHooks(hooks, rootrepo, pluginfile) "{{{3
    let hooks = filter(copy(a:hooks), 'a:pluginfile =~ v:key')
    if !empty(hooks)
        for [filename_rx, myhooks] in items(hooks)
            " Run each hook only once
            call remove(a:hooks, filename_rx)
            for hook in myhooks
                exec hook
            endfor
        endfor
    endif
endf


function! s:LoadRequiredPlugins() "{{{3
    call s:AddRepo(keys(s:reg), 0)
    if !empty(s:reg)
        for [rootrepo, pluginfiles] in items(s:reg)
            call s:LoadPlugins(0, rootrepo, pluginfiles)
        endfor
    endif
endf


" :nodoc:
function! TPluginRequire(mode, root, repo, ...) "{{{3
    let [root, rootrepo, plugindir] = s:GetRootPluginDir(a:root, a:repo)
    " echom "DBG TPluginRequire" root rootrepo plugindir !has_key(s:done, rootrepo)
    if empty(a:000) || a:1 == '*'
        let pluginfiles = split(glob(TPluginFileJoin(plugindir, '*.vim')), '\n')
    elseif a:1 == '.'
        let pluginfiles = []
    else
        let pluginfiles = map(copy(a:000), 'TPluginFileJoin(plugindir, v:val .".vim")')
    endif
    " echom "DBG TPluginRequire pluginfiles:" string(pluginfiles) (a:mode || !has('vim_starting'))
    call filter(pluginfiles, 'v:val !~ ''\V\[\/]'. g:tplugin_file .'\(_\S\{-}\)\?\.vim\$''')
    if a:mode || !has('vim_starting')
        call s:AddRepo([rootrepo], s:IsFlatRoot(root))
        call s:LoadPlugins(a:mode, rootrepo, pluginfiles)
    else
        if !has_key(s:reg, rootrepo)
            let s:reg[rootrepo] = []
        endif
        let s:reg[rootrepo] += pluginfiles
    endif
endf


function! s:RemoveAutoloads(pluginfile, commands) "{{{3
    if has_key(s:maps, a:pluginfile)
        for [keys, map] in items(s:maps[a:pluginfile])
            call s:Unmap(map, keys)
        endfor
        call remove(s:maps, a:pluginfile)
    endif

    let pluginkey = s:CommandKey(a:pluginfile)
    if empty(a:commands)
        if has_key(s:command_nobang, pluginkey)
            let cmds = keys(s:command_nobang[pluginkey])
        else
            return
        endif
    else
        let cmds = a:commands
    endif

    let remove = !empty(a:commands) && has_key(s:command_nobang, pluginkey)
    for c in cmds
        if exists(':'. c) == 2
            exec 'delcommand '. c
        endif
        if remove && has_key(s:command_nobang[pluginkey], c)
            call remove(s:command_nobang[pluginkey], c)
        endif
    endfor
    if remove && empty(s:command_nobang[pluginkey])
        call remove(s:command_nobang, pluginkey)
    endif
endf


function! s:TPluginComplete(ArgLead, CmdLine, CursorPos) "{{{3
    let repo = matchstr(a:CmdLine, '\<TPlugin\s\+\zs\(\S\+\)\ze\s')
    let rv = keys(s:repos)
    call filter(rv, 'v:val =~ a:ArgLead')
    let root = s:GetRoot()
    if empty(repo)
        if root =~ '[\\/]\*$'
            let files = ['- ']
        else
            let pos0  = len(root) + 1
            let files = split(glob(TPluginFileJoin(root, '*')), '\n')
            call map(files, 'strpart(v:val, pos0)')
            call filter(files, 'stridx(v:val, a:ArgLead) != -1')
        endif
    else
        let [root, rootrepo, plugindir] = s:GetRootPluginDir(root, repo)
        let pos0  = len(plugindir) + 1
        let files = split(glob(TPluginFileJoin(plugindir, '*.vim')), '\n')
        call map(files, 'strpart(v:val, pos0, len(v:val) - pos0 - 4)')
        call filter(files, 'stridx(v:val, a:ArgLead) != -1')
    endif
    call filter(files, 'v:val !~ ''\V'. g:tplugin_file .'\(_\w\+\)\?\(\.vim\)\?\$''')
    call filter(files, 'index(rv, v:val) == -1')
    let rv += files
    return rv
endf


function! s:IsFlatRoot(root) "{{{3
    return a:root =~ '[\\/]\*$'
endf


function! s:GetRootPluginDir(root, repo) "{{{3
    if empty(a:root)
        let root = TPluginGetRootDirOnDisk(get(s:repos, a:repo, s:GetRoot()))
    else
        let root = a:root
    endif
    let root = TPluginGetRootDirOnDisk(root)
    let repo = s:IsFlatRoot(a:root) ? '-' : a:repo
    " deprecated
    if repo == '.'
        let rootrepo = root
    else
        if repo == '-'
            let rootrepo = root
        else
            let rootrepo = TPluginFileJoin(root, repo)
        endif
    endif
    if repo == '-'
        let plugindir = rootrepo
    else
        let plugindir = TPluginFileJoin(rootrepo, 'plugin')
    endif
    return [root, rootrepo, plugindir]
endf


function! s:GetPluginFile(root, repo, plugin) "{{{3
    let [root, rootrepo, plugindir] = s:GetRootPluginDir(a:root, a:repo)
    return printf('%s/%s.vim', plugindir, a:plugin)
endf


" :display: TPluginFunction(FUNCTION, REPOSITORY, [PLUGIN])
" Load a certain plugin on demand (aka autoload) when FUNCTION is called 
" for the first time.
function! TPluginFunction(...) "{{{3
    let fn = a:000[0]
    if g:tplugin_autoload && !exists('*'. fn)
        let s:functions[fn] = [s:GetRoot()] + a:000
    endif
endf


" :display: TPluginCommand(COMMAND, REPOSITORY, [PLUGIN])
" Load a certain plugin on demand (aka autoload) when COMMAND is called 
" for the first time. Then call the original command.
"
" For most plugins, |:TPluginScan| will generate the appropriate 
" TPluginCommand commands for you. For some plugins, you'll have to 
" define autocommands yourself in the |vimrc| file.
"
" Example: >
"   TPluginCommand TSelectBuffer vimtlib tselectbuffer
function! TPluginCommand(...) "{{{3
    let cmd = a:000[0]
    if g:tplugin_autoload && exists(':'. matchstr(cmd, '\s\zs\u\w*$')) != 2
        let args = [s:GetRoot()] + a:000
        if a:0 <= 1
            echoerr "TPluginCommand: too few arguments: ". string(a:000)
        elseif a:0 <= 2
            call add(args, '*')
        elseif a:0 <= 3
        else
            echoerr "TPluginCommand: too many arguments: ". string(a:000)
        endif
        if cmd =~ '\s-range[[:space:]=]'
            let range = '["<line1>", "<line2>"]'
        elseif cmd =~ '\s-count[[:space:]=]'
            let range = '["<count>"]'
        else
            let range = '[]'
        end
        exec s:DefineCommand(a:000) .' call s:Autoload(1, '. string(args) .', "<bang>", '. range .', <q-args>)'
    endif
endf


" :display: TPluginAddRoots(?subdir="bundle")
" Add all directories named SUBDIR as roots.
function! TPluginAddRoots(...) "{{{3
    let subdir = a:0 >= 1 ? a:1 : 'bundle'
    let myroot = ''
    for dir in split(finddir(subdir, &rtp), '\n')
        " echom "DBG TPluginAddRoots" dir
        if empty(myroot)
            let myroot = dir
        endif
        call s:SetRoot(dir)
    endfor
    if !empty(myroot)
        call s:SetRoot(myroot)
    endif
endf


function! TPluginDependencies(repo, deps) "{{{3
    if !has_key(s:dependencies, a:repo)
        let s:dependencies[a:repo] = a:deps
    endif
endf


function! TPluginVimEnter(group) "{{{3
    redir => aus
    exec 'silent au' a:group 'VimEnter'
    redir END
    let au = split(aus, '\n')
    " TLogVAR a:group, len(au)
    if len(au) > 1
        exec 'doautocmd' a:group 'VimEnter'
    endif
endf


if index(['.vim', 'vimfiles'], expand("<sfile>:p:h:h:t")) != -1
    call TPluginAddRoots()
else
    call s:SetRoot(expand("<sfile>:p:h:h:h"))
endif

augroup TPlugin
    autocmd!
    autocmd VimEnter * call s:LoadRequiredPlugins()

    if g:tplugin_autoload
        autocmd FuncUndefined * call s:AutoloadFunction(expand("<afile>"))
        autocmd FileType * if has_key(s:ftypes, &ft) | call s:LoadFiletype(&ft) | endif
    endif
augroup END


let &cpo = s:save_cpo
unlet s:save_cpo
