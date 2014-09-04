# use R scripts in Ruby
require 'rinruby'

# base scripts
f1 = File.readlines('.\base_scripts\1dependencies.txt')
f2 = File.readlines('.\base_scripts\2watcher.txt')
f3 = File.readlines('.\base_scripts\3start_workflow.txt')
f5 = File.readlines('.\base_scripts\5convert_to_idf.txt')
f6 = File.readlines('.\base_scripts\6add_energyplus_measures.txt')
f7 = File.readlines('.\base_scripts\7set_tools.txt')
f9 = File.readlines('.\base_scripts\9start_run.txt')

# read in the R-script with rinruby, and for each 

# generate

# think about 

# create unique filename here, and use join to create the string to it

File.open('.\run_scripts\run_script.rb','w') do |mergedFile|
  mergedFile << [f1,"\n",f2,"\n",f3,"\n",f5,"\n",f6,"\n",f7,"\n",f9]
end