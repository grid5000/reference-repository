$LOAD_PATH.unshift(File.expand_path(File.dirname(__FILE__)))
require 'spec_helper'

gen_stub('data_graffiti', 'nancy', 'graffiti')
gen_stub('data_grimoire', 'nancy', 'grimoire')
gen_stub('data_graphite', 'nancy', 'graphite')
gen_stub('data_yeti', 'grenoble', 'yeti')
gen_stub('data_dahu', 'grenoble', 'dahu', 8)
gen_stub('data_grue', 'nancy', 'grue')
gen_stub('data_abacus22_2cpu1gpu', 'rennes', 'abacus22')
