reference-repository specs
==========================

This directory contains a test suite for the ref-repo OAR properties generator.

The tests are split into different files:
- `oar_properties_arguments_spec.rb` contains basic tests for all arguments passed to the generator
- `oar_properties_spec.rb` contains various fictious tests
- `oar_properties2_spec.rb` contains various tests based on real data

Both `oar_properties_spec.rb` and `oar_properties2_spec.rb` rely on a
`check_oar_properties` method that uses input files from `input`, and
compares the generated results to files in `output`.
For example, `check_oar_properties({ :oar => 'oar_empty', :data => 'data', :case => 'empty' })`
will use `input/oar_empty.json` and `input/data.json`, and compare the results
to `output/empty_{print,diff,table}_*.json`.

How to update input files:
==========================

data_* files:
-------------
Execute spec/regen_input_data.rb

Some files are directly copied from the current state of the ref-repo. Others were forged manually, which means that it is painful when
new fields are added.

oar_* files:
------------
Except the oar_empty.json file which should not have to be regenerated, the other files must be forged from the output of the OAR API.

Steps are:
- fetch the OAR API output for the site: `curl 'https://api.grid5000.fr/stable/sites/nancy/internal/oarapi/resources/details.json?limit=999999' > oar_site.json`
- sort the objects with jq: `cat oar_site.json | jq -S "." > new_oar_site.json; mv {new_,}oar_site.json`
- replace the tested cluster names, e.g. with sed: `sed -ie 's/graffiti/clustera/g' oar_site.json`.
- modify the oar_site.json file as needed for what should be tested.

Since using `vimdiff` or `meld` on the files is very slow, one can use the `diff` and `patch` commands...

Then verify using `git diff` that the generated data matches what you expect.

How to update the output files:
===============================

To update the files, just remove them and run rspec again, they will be regenerated.
Then verify using `git diff` that the generated data matches what you expect.
