MediaWiki stemmer
=================

This is a project which tries to stem the words of a Wikipedia/Mediawiki article then enrichen its internal links structure.

HOWTO create the Wikipedia internal links structure
===================================================
# Intall SQLite 3.8 or better (in v3.7 the .import functionality is severely broken)
# Uncompress the enwiki-latest-all-titles-in-ns0_ASCII_Unique.xz file
# Import the uncompressed data into the database:
```
sqlite3 wiki-pages.db
.mode line
.import enwiki-latest-all-titles-in-ns0_ASCII_Unique Titles
```