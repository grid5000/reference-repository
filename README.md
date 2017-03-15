The reference API data of Grid'5000 is stored in a git repository as JSON files. Those files are organized into hierarchical folders (see data/). The git repository comes with scripts to ease the generation of those API files (see generators/). The generator uses data from input/. The node information (input/grid5000/sites/*/clusters/*/nodes/*.yaml) is fetched using [g5k-checks](https://github.com/grid5000/g5k-checks). The other input files are created manually.

The git repository also includes scripts for generating:
* The OAR properties ie. the node information that is registered in OAR databases. OAR properties allow user to select resources matching their experiment requirements.
* The configuration files of the following puppet modules: bindg5kb, conmang5k, dhcpg5k, kadeployg5k and lanpowerg5k.

Automated tasks are provided to validate and generate data:

``
rake oar:properties          # Generate oar properties
rake puppet:all              # Launch all puppet generators
rake puppet:bindg5k          # Generate bindg5k configuration
rake puppet:conmang5k        # Generate conmang5k configuration
rake puppet:dhcpg5k          # Generate dhcpg5k configuration
rake puppet:kadeployg5k      # Generate kadeployg5k configuration
rake puppet:lanpowerg5k      # Generate lanpowerg5k configuration
rake reference-api           # Creates json data from inputs
rake validators:homogeneity  # Check homogeneity of clusters
rake validators:schema       # Check input data schema validity
``

For more information about generators and validators, please see generators/README.md.
