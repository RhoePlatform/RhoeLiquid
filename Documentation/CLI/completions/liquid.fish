function __liquid_should_offer_completions_for_flags_or_options -a expected_commands
    set -l non_repeating_flags_or_options $argv[2..]
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __liquid_parse_tokens
    test "$commands" = "$expected_commands"; and return $non_repeating_flags_or_options_absent
end

function __liquid_should_offer_completions_for_positional -a expected_commands positional_index_comparison expected_positional_index
    set -l non_repeating_flags_or_options
    set -l non_repeating_flags_or_options_absent 0
    set -l positional_index 0
    set -l commands
    __liquid_parse_tokens
    test "$commands" = "$expected_commands" -a \( "$positional_index" "$positional_index_comparison" "$expected_positional_index" \)
end

function __liquid_parse_tokens -S
    set -l unparsed_tokens (__liquid_tokens -pc)
    switch $unparsed_tokens[1]
    case 'liquid'
        __liquid_parse_subcommand 0 'version' 'h/help'
        switch $unparsed_tokens[1]
        case 'render'
            __liquid_parse_subcommand 1 'context=' 'o/output=' 'metrics' 'version' 'h/help'
        case 'analyze'
            __liquid_parse_subcommand 1 'format=' 'version' 'h/help'
        case 'batch'
            __liquid_parse_subcommand 1 'context-dir=' 'o/output=' 'concurrency=' 'continue-on-error' 'version' 'h/help'
        case 'validate'
            __liquid_parse_subcommand 1 'verbose' 'version' 'h/help'
        case 'benchmark'
            __liquid_parse_subcommand 1 'i/iterations=' 'context=' 'version' 'h/help'
        case 'init'
            __liquid_parse_subcommand 1 'type=' 'git' 'version' 'h/help'
        case 'help'
            __liquid_parse_subcommand -r 1 'version'
        end
    end
end

function __liquid_tokens
    if test (string split -m 1 -f 1 -- . "$FISH_VERSION") -gt 3
        commandline --tokens-raw $argv
    else
        commandline -o $argv
    end
end

function __liquid_parse_subcommand -S -a positional_count
    argparse -s r -- $argv
    set -l option_specs $argv[2..]
    set -l is_repeating_positional $_flag_r
    set -el _flag_r
    set -a commands $unparsed_tokens[1]
    set positional_index 0
    while true
        set -e unparsed_tokens[1]
        argparse -sn "$commands" $option_specs -- $unparsed_tokens 2> /dev/null
        set unparsed_tokens $argv
        set positional_index (math $positional_index + 1)
        for non_repeating_flag_or_option in $non_repeating_flags_or_options
            if set -ql "_flag_$(string replace -a - _ -- $non_repeating_flag_or_option)"
                set non_repeating_flags_or_options_absent 1
                break
            end
        end
        test (count $unparsed_tokens) -eq 0 -o \( -z "$is_repeating_positional" -a "$positional_index" -gt "$positional_count" \) && break
    end
end

function __liquid_complete_directories
    set -l token (commandline -t)
    string match -- '*/' $token
    set -l subdirs $token*/
    printf %s\n $subdirs
end

function __liquid_custom_completion
    set -x SAP_SHELL fish
    set -x SAP_SHELL_VERSION $FISH_VERSION
    set -l tokens (__liquid_tokens -p)
    if test -z "$(__liquid_tokens -t)"
        set -l index (count (__liquid_tokens -pc))
        set tokens $tokens[..$index] \'\' $tokens[(math $index + 1)..]
    end
    command $tokens[1] $argv $tokens
end

complete -c 'liquid' -f
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid" version' -l 'version' -d 'Show the version.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_positional "liquid" -eq 1' -fa 'render' -d 'Render a Liquid template.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_positional "liquid" -eq 1' -fa 'analyze' -d 'Analyze template structure and complexity.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_positional "liquid" -eq 1' -fa 'batch' -d 'Batch-render multiple templates.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_positional "liquid" -eq 1' -fa 'validate' -d 'Validate Liquid template syntax.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_positional "liquid" -eq 1' -fa 'benchmark' -d 'Benchmark template rendering performance.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_positional "liquid" -eq 1' -fa 'init' -d 'Initialize a new Liquid template project.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_positional "liquid" -eq 1' -fa 'help' -d 'Show subcommand help information.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_positional "liquid render" -eq 1' -fa '(set -l exts \'liquid\' \'html\';for p in (string match -e -- \'*/\' (commandline -t);or printf \n)*.{$exts};printf %s\n $p;end;__fish_complete_directories (commandline -t) \'\')'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid render" context' -l 'context' -d 'Context data file containing a JSON object.' -rfa '(for p in (string match -e -- \'*/\' (commandline -t);or printf \n)*.\'json\';printf %s\n $p;end;__fish_complete_directories (commandline -t) \'\')'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid render" o output' -l 'output' -s 'o' -d 'Output file path. Defaults to stdout.' -rF
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid render" metrics' -l 'metrics' -d 'Show render timing and byte-size metrics.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid render" version' -l 'version' -d 'Show the version.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid render" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_positional "liquid analyze" -eq 1' -fa '(set -l exts \'liquid\' \'html\';for p in (string match -e -- \'*/\' (commandline -t);or printf \n)*.{$exts};printf %s\n $p;end;__fish_complete_directories (commandline -t) \'\')'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid analyze" format' -l 'format' -d 'Output format: terminal, json, or markdown.' -rfka 'terminal json markdown'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid analyze" version' -l 'version' -d 'Show the version.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid analyze" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_positional "liquid batch" -eq 1' -fa '(__liquid_complete_directories)'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid batch" context-dir' -l 'context-dir' -d 'Directory containing optional JSON context files.' -rfa '(__liquid_complete_directories)'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid batch" o output' -l 'output' -s 'o' -d 'Output directory.' -rfa '(__liquid_complete_directories)'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid batch" concurrency' -l 'concurrency' -d 'Maximum number of parallel renders. Must be greater than zero.' -rfka ''
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid batch" continue-on-error' -l 'continue-on-error' -d 'Continue rendering remaining templates after a failure.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid batch" version' -l 'version' -d 'Show the version.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid batch" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_positional "liquid validate" -eq 1' -fa '(set -l exts \'liquid\' \'html\';for p in (string match -e -- \'*/\' (commandline -t);or printf \n)*.{$exts};printf %s\n $p;end;__fish_complete_directories (commandline -t) \'\')'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid validate" verbose' -l 'verbose' -d 'Show detailed output for each valid file.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid validate" version' -l 'version' -d 'Show the version.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid validate" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_positional "liquid benchmark" -eq 1' -fa '(set -l exts \'liquid\' \'html\';for p in (string match -e -- \'*/\' (commandline -t);or printf \n)*.{$exts};printf %s\n $p;end;__fish_complete_directories (commandline -t) \'\')'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid benchmark" i iterations' -l 'iterations' -s 'i' -d 'Number of render iterations. Must be greater than zero.' -rfka ''
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid benchmark" context' -l 'context' -d 'Context data file containing a JSON object.' -rfa '(for p in (string match -e -- \'*/\' (commandline -t);or printf \n)*.\'json\';printf %s\n $p;end;__fish_complete_directories (commandline -t) \'\')'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid benchmark" version' -l 'version' -d 'Show the version.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid benchmark" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid init" type' -l 'type' -d 'Project type: simple, web, api, or documentation.' -rfka 'simple web api documentation'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid init" git' -l 'git' -d 'Initialize a git repository.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid init" version' -l 'version' -d 'Show the version.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid init" h help' -s 'h' -l 'help' -d 'Show help information.'
complete -c 'liquid' -n '__liquid_should_offer_completions_for_flags_or_options "liquid help" version' -l 'version' -d 'Show the version.'
