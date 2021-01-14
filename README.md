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

 *— [Jonathan Dowland](https://jmtd.net), 2021-01-14*
