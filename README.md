MediaWiki stemmer
=================

This project tries to stem the words of a Wikipedia/MediaWiki article then enrichen its internal links structure.

Create the Wikipedia internal links structure
---------------------------------------------------
1. Install SQLite 3.8 or better (in v3.7 the .import functionality is severely broken)
2. For stemming `hunspell` is required 
3. Uncompress the `enwiki-latest-all-titles-in-ns0_ASCII_Unique.xz` file
4. Import the uncompressed data into the database:
```
sqlite3 wiki-pages.db
.mode line
.import enwiki-latest-all-titles-in-ns0_ASCII_Unique Titles
.quit
```

Run the application
-------------------
```
perl stemmer.pl <Wikipedia page name> <isStemmingRequired>
```
* `Wikipedia page name`: Name of a Wikipedia article
* `isStemmingRequired`: 1 or 0, depending on whether you want to stem the article words for best matching

Sample output
-------------
```
.------------------------------+------------------------------------------------.
| Stemmer's new links          | Wikipedia existing links                       |
+------------------------------+------------------------------------------------+
| KDE                          | International Data Corporation                 |
| LGPL                         | International Organization for Standardization |
| LMI                          | Internet Relay Chat                            |
| LUGs                         | Interoperability                               |
| Labs                         | Intuit                                         |
| Laptop                       | Java (programming language)                    |
| Later                        | Java Virtual Machine                           |
| Linus                        | JikesRVM                                       |
| Linus Torvalds               | Joe Ossanna                                    |
| Linux                        | KDE                                            |
| Linux Server                 | KDE Plasma Desktop                             |
| Linux community              | KDE Software Compilation                       |
| Linux desktop                | KDevelop                                       |
| Linux distribution           | KWin                                           |
| Linux distributions          | Kaffe                                          |
| Linux focus                  | Ken Thompson                                   |
| Linux kernel                 | Kerala                                         |
| Linux-based operating system | Kernel (computer science)                      |
| MINIX                        | Kernel (computing)                             |
| Mac                          | Knoppix                                        |
| Mac OS                       | Korg KRONOS                                    |
| Mac OS X                     | Korg OASYS                                     |
'------------------------------+------------------------------------------------'
```

Statistics
----------
The program also provides some statistics, eg. on 'Linux' article with stemming:
```
.---------------------------------------+------.
| Statistics                            |      |
+---------------------------------------+------+
| Number of links in Wikipedia article: | 360  |
| Number of new links found:            | 1292 |
'---------------------------------------+------'
```

... and without stemming:
```
.---------------------------------------+------.
| Statistics                            |      |
+---------------------------------------+------+
| Number of links in Wikipedia article: | 360  |
| Number of new links found:            | 1140 |
'---------------------------------------+------'
```