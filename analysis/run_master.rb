# run master.rb
# runs all the ruby scripts for each unique simulation,
# and deletes extraneous files.
#
# Building Science Group 2014
#
# Contributors:
# Matthew G. Dahlhausen

# should really be doing this with a rake file
# task :default do
#    FileList['file*.rb'].each { |file| ruby file }
# end

run_scripts = Dir["run_scripts/*.rb"]

puts "#{run_scripts}"

run_scripts.each do |script|
  puts "\n***************\nRUNNING SCRIPT: #{script} \n"
  output = system("ruby #{script}")
  puts "\nSCRIPT COMPLETED SUCCESSFULLY: #{output} \n***************\n"
end

# to set to prior directory
# {File.expand_path("..",Dir.pwd)
