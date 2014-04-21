#!/usr/bin/env ruby

require 'optparse'
require 'nokogiri'

$options = {}
opt_parser = OptionParser.new do |opts|
	opts.banner = "Usage: patch_xml.rb [options]"

	opts.on("-i", "--input FILE", "Input Mapnik XML style file") do |v|
		$options[:input] = v
	end

	opts.on("-o", "--output FILE", "Output Mapnik XML style file") do |v|
		$options[:output] = v
	end

	opts.on("--host HOST", "Override host option") do |v|
		$options[:host] = v
	end

	opts.on("--user USER", "Override user option") do |v|
		$options[:user] = v
	end

	opts.on("--password PASS", "Override password option") do |v|
		$options[:password] = v
	end

	opts.on("--dbname DBNAME", "Override dbname option") do |v|
		$options[:dbname] = v
	end

	opts.on("-h", "--help", "Show help") do
		$stderr.puts opt_parser.help
		exit 1
	end
end

opt_parser.parse!

if $options[:input].nil? then
	$stderr.puts opt_parser.help
	exit 1
end

def to_text(node)
	if node.nil? then
		nil
	else
		node.text
	end
end

def set_val(node, val)
	tmp = Nokogiri::XML::Document.new
	node.children = tmp.create_cdata(val)
end

f = File.open($options[:input])
doc = Nokogiri::XML(f)
f.close

doc.xpath('/Map/Layer/Datasource').each { |datasource|
	next if 'postgis' != to_text(
		datasource.xpath('./Parameter[@name="type"]').first
	)

	if !$options[:host].nil? then
		datasource.xpath('./Parameter[@name="host"]').each { |v|
			set_val(v, $options[:host])
		}
	end

	if !$options[:user].nil? then
		datasource.xpath('./Parameter[@name="user"]').each { |v|
			set_val(v, $options[:user])
		}
	end

	if !$options[:password].nil? then
		datasource.xpath('./Parameter[@name="password"]').each { |v|
			set_val(v, $options[:password])
		}
	end

	if !$options[:dbname].nil? then
		datasource.xpath('./Parameter[@name="dbname"]').each { |v|
			set_val(v, $options[:dbname])
		}
	end
}

out_xml = doc.to_xhtml(:indent => 4, :encoding => 'UTF-8')
if $options[:output] then
	File.open($options[:output], 'w') { |file| file.write(out_xml) }
else
	puts out_xml
end
