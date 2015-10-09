conn = PG.connect( ENV['RAILGUN_DATABASE'] )
$result = {}
conn.exec "SELECT HOST(address) AS host, NETMASK(address) AS netmask FROM addresses WHERE region_id = 2 OR region_id = 3" do |result|
  result.each do |row|
    puts "route #{row['host']} #{row['netmask']} net_gateway 5"
  end
end
