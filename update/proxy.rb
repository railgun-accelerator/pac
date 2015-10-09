DIRECT = ['.cn']
PROXY = ['.x.com.cn']


require 'json'
require 'ipaddr'
require 'set'

require 'pg'
require 'public_suffix'

conn = PG.connect(ENV['RAILGUN_DATABASE'])
$addresses = {}
conn.exec "select address - '0.0.0.0'::inet as host_integer, netmask(address) - '0.0.0.0'::inet as netmask_integer from addresses where region_id = 2 or region_id = 3" do |result|
  result.each do |row|
    $addresses[row['netmask_integer'].to_i] ||= {}
    $addresses[row['netmask_integer'].to_i][row['host_integer'].to_i] = true
  end
end
#puts 'var addresses=' + $addresses.to_json

domains_traffic = Hash.new 0
domains_address = {}

while line = gets
  begin
    line = line.split(' ')
    address = line[8].split('/')[1]
    if line[3].split('/')[0] == 'TCP_TUNNEL'
      domain = line[6].split(':')[0]
    else
      domain = line[6].split('//')[1]
      if domain
        domain = domain.split('/')[0].split(':')[0]
      else
        next
      end
    end
    traffic = line[4].to_i

    domains_traffic[domain] += traffic
    domains_address[domain] = address unless address == '-'
  rescue
    nil # skip this line
  end
end

domains_address.dup.each do |domain, address|
  if PublicSuffix.valid? domain
    domains_address[domain] = $addresses.any? { |netmask, hosts| hosts.include? IPAddr.new(address).to_i & netmask }
    1.upto (domain.count('.') - PublicSuffix.parse(domain).domain.count('.')) do |level|
      d = domain.split('.', level+1)[-1]
      domains_address[d] = nil unless domains_address.has_key? d
    end
  else
    domains_address.delete domain
  end
end

$direct_tree = Set.new
$direct_exact = Set.new
$proxy_tree = Set.new


domains = domains_address.keys.sort_by { |domain| domain.reverse }

i = 0
while i < domains.length
  domain = domains[i]
  if domains_address[domain] == false
    i += 1
  else
    j = i
    if loop do
      j+=1
      if j < domains.length and domains[j].end_with? '.'+domain
        break true if domains_address[domains[j]] == false
      else
        $direct_tree.add domain
        i = j
        j = true
        break false
      end
    end
      $direct_exact.add domain if domains_address[domain]
      i += 1
    end
  end
end

DIRECT.each do |domain|
  if domain[0] == '.'
    $direct_tree.reject! { |d| d == domain or d.end_with? domain }
    $direct_exact.reject! { |d| d == domain or d.end_with? domain }
    $direct_tree.add domain[1, domain.length-1]
  else
    raise
  end
end


PROXY.each do |domain|
  if domain[0] == '.'
    $proxy_tree.add domain[1, domain.length-1]
    $direct_tree.reject! { |d| d == domain or d.end_with? domain }
    $direct_exact.reject! { |d| d == domain or d.end_with? domain }
  else
    raise
  end
end

def domain_list(domains)
  result = domains.group_by { |domain| domain.count('.') + 1 }
  result.each do |level, domains|
    result[level] = {}
    domains.each { |domain| result[level][domain] = true }
  end
end

puts "var direct_addresses=#{$addresses.to_json}, direct_tree=#{domain_list($direct_tree).to_json}, direct_exact=#{domain_list($direct_exact).to_json}, proxy_tree=#{domain_list($proxy_tree).to_json};"