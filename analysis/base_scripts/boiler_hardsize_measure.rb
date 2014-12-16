# SetBoilerCapacity measure
dir = OpenStudio::Path.new("#{Dir.pwd}/hardsizing_measures/SetBoilerCapacity")             
measure = OpenStudio::BCLMeasure::load(dir)
args  = OpenStudio::Ruleset::OSArgumentVector.new()

boiler_bool = OpenStudio::Ruleset::OSArgument::makeBoolArgument("boiler_bool")
boiler_bool.setValue(false)
args << boiler_bool

boiler_display_names = OpenStudio::StringVector.new
boiler_display_names << ''
boiler_display_names << 'Boiler Hot Water 1'
boiler_name = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("boiler_name", boiler_display_names)
boiler_name.setValue("Boiler Hot Water 1")
args << boiler_name

# sql_path set in run_generation.rb
sql_fname = OpenStudio::Ruleset::OSArgument.makeStringArgument("sql_fname")
sql_fname.setValue(sql_path)
args << sql_fname

rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args);
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath());
wf.addJob(rubyjobbuilder.toWorkItem());