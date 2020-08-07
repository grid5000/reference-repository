How to update input files:
==========================

data_* files:
-------------
Uncomment the corresponding `gen_stub()` line in ../oar_properties2_spec.rb and re-run rspec.

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
