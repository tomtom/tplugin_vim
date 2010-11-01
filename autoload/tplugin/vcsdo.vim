" vcsdo.vim
" @Author:      Tom Link (mailto:micathom AT gmail com?subject=[vim])
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     2010-10-31.
" @Last Change: 2010-11-01.
" @Revision:    71

if !has('ruby')
    echoerr 'tplugin#vcsdo requires compiled-in ruby support'
    finish
endif


if !exists('g:tplugin#vcsdo#script')
    " The filename of the vcsdo executable.
    let g:tplugin#vcsdo#script = ''   "{{{2
endif


if !exists('g:tplugin#vcsdo#log_buffer')
    " Name of the log buffer.
    " If empty, print log lines as messages.
    let g:tplugin#vcsdo#log_buffer = '__TPluginUpdateLog__'   "{{{2
endif


if !exists('g:tplugin#vcsdo#exclude_roots_rx')
    " Don't update root directories matching this |regexp|.
    let g:tplugin#vcsdo#exclude_roots_rx = ''   "{{{2
endif


let g:tplugin#vcsdo#script = fnamemodify(g:tplugin#vcsdo#script, ':p')
if !executable(g:tplugin#vcsdo#script)
    echoerr 'Please set g:tplugin#vcsdo#script to the filename of the vcsdo executable'
    finish
endif


if empty(g:tplugin#vcsdo#log_buffer)

ruby <<RUBY
class << $stdout
    def close
    end
end
RUBY

else


let g:tplugin#vcsdo#log_buffer = fnamemodify(g:tplugin#vcsdo#log_buffer, ':p')

ruby <<RUBY
class VimLogBuffer
    def write(string)
        VIM::command('call s:ShowLog()')
        VIM::command('call append(line("$"), %s)' % string.chomp.inspect)
        VIM::command('$')
        VIM::command('redraw')
    end

    def close
    end
end
RUBY

endif

exec 'rubyfile '. fnameescape(g:tplugin#vcsdo#script)


" :nodoc:
function! tplugin#vcsdo#Update(dry, roots) "{{{3
    " TLogVAR a:dry, a:roots
    for root in a:roots
        if !empty(g:tplugin#vcsdo#exclude_roots_rx) && root =~ g:tplugin#vcsdo#exclude_roots_rx
            continue
        endif
        ruby << RUBY
        if VCSDo::VERSION < '0.2'
            VIM::command('echoerr "tplugin requires VCSDO version >= 0.2"')
        else
            args = ['-e', VIM::evaluate('root'), 'update']
            if VIM::evaluate('a:dry') != 0
                args.unshift('-n')
            end
            if defined?(VimLogBuffer)
                begin
                    stdout = $stdout
                    $stdout = VimLogBuffer.new
                    VCSDo.with_args(args).process
                ensure
                    $stdout = stdout
                end
            else
                VCSDo.with_args(args).process
            end
        end
RUBY
    endfor
endf


" :nodoc:
function! s:ShowLog() "{{{3
    if bufwinnr(g:tplugin#vcsdo#log_buffer) == -1
        exec 'split' fnameescape(g:tplugin#vcsdo#log_buffer)
        setlocal buftype=nofile
        setlocal bufhidden=hide
        setlocal noswapfile
        setlocal nobuflisted
        setlocal foldmethod=manual
        setlocal modifiable
        setlocal nospell
    else
        exec 'drop' fnameescape(g:tplugin#vcsdo#log_buffer)
    endif
endf

