# load gems used by most of refrepo scripts
require 'erb'
require 'fileutils'
require 'json'
require 'net/http'
require 'net/https'
require 'open-uri'
require 'optparse'
require 'pathname'
require 'pp'
require 'set'
require 'time'
require 'uri'
require 'yaml'
require 'ipaddress'


# pre-declare those modules here
module RefRepo
end
module RefRepo::Gen
end
module RefRepo::Valid
end
# load sub-parts that are used by many scripts anyway
require 'refrepo/utils'
require 'refrepo/input_loader'
