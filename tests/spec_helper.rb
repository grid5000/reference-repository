require 'simplecov'

SimpleCov.start do
  add_filter '/tests/'
  add_filter '/bundle/'
end
# This outputs the report to your public folder
# You will want to add this to .gitignore
SimpleCov.coverage_dir 'coverage'
