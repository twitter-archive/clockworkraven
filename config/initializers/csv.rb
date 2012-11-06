if RUBY_VERSION < "1.9"
  require "rubygems"
  require "fastercsv"
  CSV = FCSV
else
  require "csv"
end