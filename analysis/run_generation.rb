# run_generation.rb
# Takes in a text file of a measure table, with a corresponding letter lookup,
# and a text file of the unique simulations needed.
# It writes a run manager ruby script for each unique simulation.
# If a measure is dependent on preceding simulations,
# it will hardsize the equipment based on the .eio file of the prior simulation.
#
# Building Science Group 2014
#
# Contributors:
# Matthew G. Dahlhausen
#
# Dependencies:
# base_scripts, a unqiue_sims.txt file, and a measure_map.txt file

# base scripts
f1 = File.read("#{Dir.pwd}/base_scripts/1dependencies.rb")
f2 = File.read("#{Dir.pwd}/base_scripts/2watcher.rb")
f3 = File.read("#{Dir.pwd}/base_scripts/3start_workflow.rb")
f5 = File.read("#{Dir.pwd}/base_scripts/5convert_to_idf.rb")
f6 = File.read("#{Dir.pwd}/base_scripts/6add_energyplus_measures.rb")
f7 = File.read("#{Dir.pwd}/base_scripts/7set_tools.rb")
f9 = File.read("#{Dir.pwd}/base_scripts/9start_run.rb")
f_boiler = File.read("#{Dir.pwd}/base_scripts/boiler_hardsize_measure.rb")
f_cu = File.read("#{Dir.pwd}/base_scripts/cu_hardsize_measure.rb")

fname_runs = "#{Dir.pwd}/measures/unique_sims.txt"
fname_map = "#{Dir.pwd}/measures/measure_map.txt"

# has table for measure file lookup
measure_hash = Hash.new
dependence_hash = Hash.new
File.open(fname_map) do |f|
  f.each_line do |line|
    a = line.split(' ')
	key = "#{a[0]}"
	measure_hash[key] = a[1]
	dependence_hash[key] = a[2]
  end
end

num_scripts = 0
# create the baseline run
script_fname = "#{Dir.pwd}/run_scripts/baseline.rb"
f8 = 'outdir = OpenStudio::Path.new("#{Dir.pwd}/run_scripts/results/' + "baseline" '")'
File.open(script_fname, 'w') do |mergedFile|
  mergedFile << f1 + "\n" + f2 + "\n" + f3 + "\n" + f5 + "\n\n" +
                '# add EnergyPlus measures' + "\n" + f6 + "\n\n" +
                f7 + "\n" + '# output directory' + "\n\n" + f8 + "\n" + f9 + "\n"
end
num_scripts = num_scripts + 1 

# for each unique simulation, construct a run_script
File.readlines(fname_runs).each do |seq|
  
  # set output file directory for the script
  script_fname = "#{Dir.pwd}/run_scripts/#{seq.strip}.rb"
  
  # output directory for the run results
  f8 = 'outdir = OpenStudio::Path.new("#{Dir.pwd}/run_scripts/results/' + "#{seq.strip}" '")'

  # open and file and write the run script to it   
  File.open(script_fname, 'w') do |mergedFile|
    mergedFile << f1 + "\n" + f2 + "\n" + f3 + "\n\n" + '# ***START OSM MEASURES***' + "\n"
	
	# create array of measures in order
    runs = seq.split('_')
	runs = runs.collect { |x| x.strip }

	# add each measure to model in order
	index = 0
    runs.each do |run|
	
	  if index == 0
	    preceding_sim = "baseline"
		preceding_measure = "baseline"		
	  else
	    preceding_sim = "#{runs.slice(0,index).join("_")}"
		preceding_measure = runs[index-1]
	  end
      #puts "INDEX: #{index}, runs: #{preceding_sim}"
	  #puts "preceding_measure: #{preceding_measure}"

	  # if an HVAC measure is preceding, hardsize model based on prior run	  
      if dependence_hash[preceding_measure].to_i == 1
	    mergedFile << 'preceding_sim = ' + "'#{preceding_sim}'" + "\n"
	    mergedFile << 'preceding_files = Dir.entries("#{Dir.pwd}/run_scripts/results/" + "#{preceding_sim}")' + "\n"
	    mergedFile << 'preceding_eplus_folder = preceding_files.keep_if {|x| x.include? "EnergyPlus"}' + "\n"
	    mergedFile << 'preceding_eplus_folder = "#{Dir.pwd}/run_scripts/results/" + "#{preceding_sim}" + "/" + "#{preceding_eplus_folder[0]}" + "/"' + "\n"
		
		if measure_hash[preceding_measure].include? "Boiler"
	      mergedFile << 'sql_path = "#{preceding_eplus_folder}" + "eplusout.sql"' + "\n"
		  mergedFile << 'sql_path = "#{sql_path}"' + "\n\n"
		  mergedFile << f_boiler + "\n\n"
		end
		if measure_hash[preceding_measure].include? "TwoSpeedDXCooling"
	      mergedFile << 'eio_path = "#{preceding_eplus_folder}" + "eplusout.eio"' + "\n"
		  mergedFile << 'eio_path = "#{eio_path}"' + "\n\n"
		  mergedFile << f_cu + "\n\n"
		end
      end
		
      measure_file = "#{Dir.pwd}/measures/" + "#{measure_hash[run]}" + "/default_script.rb"
	  mergedFile << File.read(measure_file) + "\n\n"
	  index = index + 1
    end
	
	# add remainder of reporting measures and output information
    mergedFile << "\n" + '# ***END OSM MEASURES***' + "\n\n" + f5 + "\n\n" +
                  '# add E+ measures' + "\n" + f6 + "\n\n" +
                  f7 + "\n" + '# output directory' + "\n\n" + f8 + "\n" + f9 + "\n"
  end
  
  num_scripts = num_scripts + 1
end

puts "successfully wrote #{num_scripts} scripts to the run_scripts directory"