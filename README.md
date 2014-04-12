MediaWiki stemmer
=================

This project tries to stem the words of a Wikipedia/Mediawiki article then enrichen its internal links structure.

HOWTO create the Wikipedia internal links structure
===================================================
1. Intall SQLite 3.8 or better (in v3.7 the .import functionality is severely broken)
2. Uncompress the enwiki-latest-all-titles-in-ns0_ASCII_Unique.xz file
3. Import the uncompressed data into the database:
```
sqlite3 wiki-pages.db
.mode line
.import enwiki-latest-all-titles-in-ns0_ASCII_Unique Titles
```