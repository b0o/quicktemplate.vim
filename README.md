# quicktemplate.vim :rocket:
### Better Vim syntax highlighting for [Quicktemplate](https://github.com/valyala/quicktemplate)
##### :warning::construction: This plugin is a work in progress :construction::warning:

Quicktemplate is a compiled templating engine for Go. 
It has a unique syntax where all top-level text is considered a comment by default,
and directives wrapped in pairs of `{%` `%}` are used to specify desired behavior.
Many of these directives allow for embedded HTML or Go code, making good syntax 
highlighting support vital for effective and efficient development of templates.

### Installation

Install as you would any other plugin using your preferred plugin manager. 

I use dein: 
```vimscript
call dein#add('b0o/quicktemplate.vim')
```

### Known Issues

If you know how to fix any of these issues, please submit a PR!

  * [ ] Certain template blocks within HTML blocks are not highlighted
  * [ ] Function declarations do not receive Go syntax highlighting

### License

&copy; 2018 Maddison Hellstrom. Released under the MIT License.
