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

# script reference to special hardsizing measure

fname_runs = "#{Dir.pwd}/measures/unique_sims.txt"
fname_map = "#{Dir.pwd}/measures/measure_map.txt"

# file lookup for measures
measure_table = []
File.open(fname_map) do |f|
  f.each_line do |line|
    measure_table << line.split(' ')
  end
end
# puts "\nARRAY:\n",measure_table.inspect,"\n"
letters = measure_table.map { |r| r[0] }
measures = measure_table.map { |r| r[1] }
dependence = measure_table.map { |r| r[2] }

# for each unique simulation, construct a run_script
File.readlines(fname_runs).each do |seq|

  # create array of measures in order
  runs = seq.split('_')

  runs.each do |run|
    index = letters.index("#{run.strip}")
    run.replace "#{measures[index]}"
  end

  # set output file directory for the script
  script_fname = "#{Dir.pwd}/run_scripts/#{seq.strip}.rb"

  # output directory for the run results
  f8 = 'outdir = OpenStudio::Path.new("#{Dir.pwd}/run_scripts/results/' +
          "#{seq.strip}" '")'

  File.open(script_fname, 'w') do |mergedFile|
    mergedFile << f1 + "\n" + f2 + "\n" + f3 + "\n\n" + '# START OSM MEASURES' + "\n"

      runs.each do |run|
        # If a measure is dependent on preceding simulations,
        # hardsize the equipment based on the .eio file of the prior simulation.
        default_fname = "#{Dir.pwd}/measures/" + "#{run}" + "/default_script.rb"
        mergedFile << File.read(default_fname)
      end

    mergedFile << '# END OSM MEASURES' + "\n\n" + f5 + "\n\n" +
                              '# add EnergyPlus measures' + "\n" + f6 + "\n\n" +
                              f7 + "\n" + '# ouput directory' + "\n\n"+f8 + "\n\n" + f9 + "\n"
  end

end
