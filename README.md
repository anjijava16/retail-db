Retail Chain Database
=====================

Dummy retail chain database developed as an project assignment for
Data Engineering course.

Requirements:

* Postgresql 9
* GNU Make 3.81

0. Building
-----------

Database definition is split into separate SQL files for readability.
This repo comes with a `Makefile` that allows you to quickly build
`create.sql` and `clear.sql`. Simply run:

```bash
$ make
```

You may also want to deploy it to your default database

```bash
$ make deploy
```

1. Generating new ER diagram
----------------------------

You need a tool called [SchemaCrawler](http://schemacrawler.sourceforge.net/) for this.
It crawls your Postgresql database and makes a diagram out of it.
Simply deploy database using Makefile and run the following:

```bash
$ $(SCHEMACRAWLER_DIR)/sc.sh -server=postgresql -user=$(USER) -database=$(USER) -infolevel=standard -command=graph -outputformat=png -outputfile=src/diagram.png
```
