Opinionated IkiWiki
===================

This is a clone of the [IkiWiki](https://ikiwiki.info) git repository. The
"opinionated" branch is used as a basis for the [Opinionated
IkiWiki](https://github.com/jmtd/opinionated-ikiwiki) containerized version of
IkiWiki.

At the time of writing, the opinionated branch is IkiWiki tag
3.20200202.3 + the following patches
([`git log --oneline 3.20200202.3..opinionated`](https://github.com/jmtd/ikiwiki/compare/3.20200202.3...jmtd:opinionated?expand=1)):

```
841b4c2c2 admonitions: fix missing semi-colon in CSS
befc63158 Adjust basewiki front-page to demo opinionated features
f108495a1 table.pm: permit data in the "header" parameter
1ccbdf221 table.pm: treat table header as an array
dc98b8df6 table.pm: procedure-ize building data structure
21aab4a83 add a fullwidth_table CSS style to style.css
5e3866bbd Merge branch 'admonitions' into opinionated-candidate
f4c05e788 fix padding around admonitions
c4fc55a3a properly guess page formats
7b11dd491 namespace consistency, comments and fix test numbering
004d9a738 comments and better descriptions
6e0e17112 parse insides of directives normally, add unit tests
e7f82cc0d clarify workarounds
9970b8a05 markdown quirks: content inside <div>s are *not* parsed,
92dade537 replace lorem ipsum by more useful examples
e6386f1aa add documentation for the directives and sample rendering
a7e087b82 add admonition directives
be070f494 allow divs to show admonitions
a3bbdc7cc import admonitions logos from MoinMoin
6ee18bb69 DuckDuckGo: use 'sites' parameter and avoid JavaScript
ef15bfa73 Add copyright preamble comment
d167c87e7 document duckduckgo plugin
641ad4757 alias: ensure PageSpec alias definitions happen only once
2115aae24 new plugin: alias.pm - pagespec aliases
8874c7306 Initial stab at a DuckDuckGo plugin
f4755f865 new permalink plugin: defines TMPL_VAR PERMALINK
13426d868 Use the HTML5 details tag for more backlinks
daa44271b Switch from pubdate=pubdate to class=dt-published
```

 *— [Jonathan Dowland](https://jmtd.net), 2021-02-19*
