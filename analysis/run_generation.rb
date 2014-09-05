#run_generation.rb
# Takes in a text file of a measure table, with a corresponding letter lookup, and a text file of the unique simulations needed.  It writes a run manager ruby script for each unique simulation. If a measure is dependent on preceding simulations, it will hardsize the equipment based on the .eio file of the prior simulation.
#
# Building Science Group 2014
#
# Contributors: 
# Matthew G. Dahlhausen
#
# Dependencies: 
# base_scripts, a unqiue_sims.txt file, and a measure_map.txt file

# base scripts
f1 = File.readlines('.\base_scripts\1dependencies.txt')
f2 = File.readlines('.\base_scripts\2watcher.txt')
f3 = File.readlines('.\base_scripts\3start_workflow.txt')
f5 = File.readlines('.\base_scripts\5convert_to_idf.txt')
f6 = File.readlines('.\base_scripts\6add_energyplus_measures.txt')
f7 = File.readlines('.\base_scripts\7set_tools.txt')
f9 = File.readlines('.\base_scripts\9start_run.txt')

# script reference to special hardsizing measure

fname_runs = '.\measures\unique_sims.txt'
fname_map = '.\measures\measure_map.txt'

# file lookup for measures 
measure_table = []
File.open(fname_map) do |f|
  f.lines.each do |line|
    measure_table << line.split(' ')
  end
end
# puts "\nARRAY:\n",measure_table.inspect,"\n"
letters = measure_table.map{|r| r[0]}
measures = measure_table.map{|r| r[1]}
dependence = measure_table.map{|r| r[2]}

# for each unique simulation, construct a run_script
File.readlines(fname_runs).each do |seq|
  
  #create array of measures in order
  runs = seq.split('_')
  
  runs.each do |run|
    index = letters.index("#{run.strip}")
	run.replace "#{measures[index]}"
  end    
  
  # set output file directory for the script
  script_fname = "./run_scripts/#{seq.strip}.rb"
  
  # output directory for the run results
  f8 = 'outdir = OpenStudio::Path.new("./run_scripts/results/' + "#{seq.strip}" '")' 
  
  File.open(script_fname, 'w') do |mergedFile|
    mergedFile << [f1,"\n\n",f2,"\n\n",f3,"\n\n"]
    runs.each do |run|
	   
	  # If a measure is dependent on preceding simulations, hardsize the equipment based on the .eio file of the prior simulation.
		
      default_fname = '.\measures\\' + "#{run}" + '\default_script.txt'
  	  mergedFile << [File.readlines(default_fname), "\n"]
    end
    mergedFile << [f5,"\n\n",f6,"\n\n",f8,"\n\n",f7,"\n\n",f9]  
  end
  
end

