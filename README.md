CSV to BagIt
==================
csv2bag is a Ruby script that parses a CSV file for a collection, maps data fields to predicates, optionally performs cleanup and linked data lookups, and outputs [Bags](https://en.wikipedia.org/wiki/BagIt) containing RDF metadata and any associated full resolution media files. This is primarily developed for bulk ingest into [Oregon Digital](http://oregondigital.org) and was originally created as [CONTENTdm to BagIt](http://github.com/OregonDigital/cdm2bag)


#### Installation
**Requires Ruby 2.1.2** (set by .ruby-version)

```
git clone https://github.com/OregonDigital/csv2bag.git
cd csv2bag
mkdir bags
mkdir metadata
bundle install
bundle exec ./csv2bag -h
```

#### CSV Setup

csv2bag expects the .csv file to have:

* a header row as the first row
* a mapping row as the second row, where each column contains one of the following:
    * the keyword SKIP to indicate that column won't be processed
    * the term for that column
    * the method to be used to generate the term for that column in the format *method:METHOD_NAME*

The CSV file should be named **name_of_my_collection.csv** and located in the **/metadata/name_of_my_collection** folder, along with the files that are to be bagged.

##### Example CSV snippet

```
Identifer,Article Title,Rights Statement,Primary author or editor,Publisher,Place of Publication,Subject(s),Countries
dce:identifier,dct:title,method:rights,method:creator,SKIP,method:geographic_pup,method:lcsubject,method:geographic
1,Hassan - Israel Water Policy Pressurizes Occupied Arabs,Rights Restricted - Free Access,"Sorman, Unal; Balkan, Guven",Jordan Newspaper Co.,Amman,Politics and government; Armed Forces; Agriculture; Settlements,Jordan; Israel
2,"Seawater vs. Brackish Water Desalting-- Technology, Operating Problems and Overall Economics",Rights Reserved - Restricted Access,"Glueckstern, P.; Kantor, Y.",Elsevier,Amsterdam,Technology; Economics; Saline water conversion,Israel
3,Desalination at Inland Sites,http://www.europeana.eu/rights/rr-r/,"Gendel, A.",Elsevier,Amsterdam,Technology; Economics; Mediterranean Sea,Israel
```

#### Mapping
* Specify a predicate to place the field's text. For fields that don't need any cleanup or lookups done. (Examples: title, identifier, description, etc.)
* Use Dublin Core as a base element set
* Can also use any additional Linked Open Data vocabularies in [rdf-vocab](https://github.com/ruby-rdf/rdf-vocab)
* Follow the appropriate schema. ([Oregon Digital 1](https://github.com/OregonDigital/oregondigital/blob/master/app/models/datastream/oregon_rdf.rb), [ScholarsArchive@OSU](https://github.com/osulp/Scholars-Archive/blob/master/app/schemas/scholars_archive_schema.rb))

#### Methods
* Use a method for cleaning up known data errors or mapping strings to URIs
* View [List of Methods](https://github.com/OregonDigital/csv2bag/wiki/List-of-Methods)
* Define all methods in a comment (so that programmer knows intent of method)

#### Optional Parameters
* Source image files can be stored in a location other than the metadata/COLLECTION folder, and the new path can be referenced with the command line parameter **--image-file-path**
* Source image files can be mapped to a different file name using a CSV file specified in the command line parameter **--image-file**.  The CSV file must have the columns in the format of old_file,new_file and have no heading.  The file is read in and a hash of old->new can then be used in the cleanup task to convert from the old filename to the new one.
* Different log levels for console output can be specified in the command line parameter **--console-level-log**. Default is 'warn'. Logfile output is not affected.

#### Contributing
* Use [Oregon Digital Git best practices](https://github.com/OregonDigital/Dev-Standards) and make changes / additions on a branch, commit with helpful commit message, then submit a Pull Request.
* Validate syntax before commit.
