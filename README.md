Opinionated IkiWiki
===================

This is a clone of the [IkiWiki](https://ikiwiki.info) git repository. The
"opinionated" branch is used as a basis for the [Opinionated
IkiWiki](https://github.com/jmtd/opinionated-ikiwiki) containerized version of
IkiWiki.

At the time of writing, the opinionated branch is IkiWiki tag
3.20250501 + the following patches
(`git log --oneline 3.20250501..opinionated`):

```
2e97b6a6e (HEAD -> opinionated, github/opinionated) mdwn support CommonMark if available
c77dff3bd Adjust basewiki front-page to demo opinionated features
be2d0a2b9 table.pm: permit data in the "header" parameter
65ae5b0c3 table.pm: treat table header as an array
0e4fa5eda table.pm: procedure-ize building data structure
9122313a3 add a fullwidth_table CSS style to style.css
50323aad7 alias: ensure PageSpec alias definitions happen only once
0b34ccc80 new plugin: alias.pm - pagespec aliases
abc06159f new permalink plugin: defines TMPL_VAR PERMALINK
```

 *— [Jonathan Dowland](https://jmtd.net), 2025-08-29*
