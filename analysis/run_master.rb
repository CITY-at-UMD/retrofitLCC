#run_master.rb
# runs all the ruby scripts for each unique simulation, and deletes extraneous files after each simulation.
#
# Building Science Group 2014
#
# Contributors: 
# Matthew G. Dahlhausen

#should really be doing this with a rake file
#task :default do
#    FileList['file*.rb'].each { |file| ruby file }
#end

run_scripts = Dir["./run_scripts/*.rb"]

run_scripts.each do |script|
  puts "\nRUNNING SCRIPT: #{script} \n" 
  output = system("ruby #{script}")
  puts "\nRESULT: #{output} \n\n"
end

# to set to prior directory
#{File.expand_path("..",Dir.pwd)