#!/usr/bin/env ruby
require 'xml'
require 'yaml'

#
# Parse
#

drugs = {}
reader = XML::Reader.file('drugbank.xml')

while reader.read
  case reader.node_type
  when XML::Reader::TYPE_ELEMENT
    if reader.name == 'drug' && reader.depth == 1
      drug = {
        'drugbank-id' => nil,
        'name' => nil,
        'groups' => [],
        'atc-codes' => [],
        'targets' => []
      }
    elsif reader.name == 'atc-code' && reader.depth == 3
      drug['atc-codes'] << reader.get_attribute('code')
    end

  when XML::Reader::TYPE_TEXT
    parent = reader.node.parent

    if parent.name == 'drugbank-id' && parent.attributes['primary'] == 'true' && reader.depth == 3
      drug['drugbank-id'] = reader.value
    elsif parent.name == 'name' && parent.parent.name == 'drug' && reader.depth == 3
      drug['name'] = reader.value
    elsif parent.name == 'group'
      drug['groups'] << reader.value
    elsif parent.name == 'gene-name'
      drug['targets'] << reader.value
    end

  when XML::Reader::TYPE_END_ELEMENT
    if reader.name == 'drug' && reader.depth == 1
      drugs[drug['drugbank-id']] = drug
    end
  end
end

#
# Output
#

drug2targets = Hash.new { |hash, key| hash[key] = [] }
target2drugs = Hash.new { |hash, key| hash[key] = [] }

File.open('drugs.txt', 'w') do |fout|
  fout.puts "DrugBank ID\tName\tGroups\tATC Codes\tTargets"
  drugs.each_value do |drug|
    fout.puts drug.values.map { |v| v.is_a?(Array) ? v.join(', ') : v }.join("\t")

    drug['targets'].each do |target|
      drug2targets[drug['name']] << target
      target2drugs[target] << drug['name']
    end
  end
end

File.open('drug2targets.txt', 'w').puts drug2targets.to_a.map { |a| a.join("\t") }
File.open('target2drugs.txt', 'w').puts drug2targets.to_a.map { |a| a.join("\t") }
