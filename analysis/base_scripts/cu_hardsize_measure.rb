# HardsizeTwoSpeedDXCoolingCoil measure
dir = OpenStudio::Path.new("#{Dir.pwd}/hardsizing_measures/HardsizeTwoSpeedDXCoolingCoil")             
measure = OpenStudio::BCLMeasure::load(dir)
args  = OpenStudio::Ruleset::OSArgumentVector.new()
    
air_loop_handles = OpenStudio::StringVector.new
air_loop_display_names = OpenStudio::StringVector.new
building = model.getBuilding
air_loop_handles << building.handle.to_s
air_loop_display_names << "*All Air Loops*"
object = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("object", air_loop_handles, air_loop_display_names,true)
object.setValue("*All Air Loops*")
args << object	

# eio_path set in run_generation.rb
eio_fname = OpenStudio::Ruleset::OSArgument.makeStringArgument("eio_fname")
eio_fname.setValueName(eio_path)   
args << eio_fname

rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args);
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath());
wf.addJob(rubyjobbuilder.toWorkItem());