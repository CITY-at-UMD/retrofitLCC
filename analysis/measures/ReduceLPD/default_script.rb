# Reduce Lighting Power Density Measure

#populate choices for argument for fans in the model
light_handles = OpenStudio::StringVector.new
light_display_names = OpenStudio::StringVector.new

light_hash = {}  # putting fan names into hash
model.getLightsDefinitions.each do |light|
  light_hash[light.name.to_s] = light
end	

light_hash.sort.map do |light_name, light|  # looping through sorted hash of zones
  light_handles << light.handle.to_s
  light_display_names << light_name
end

# Reduce lighting power density from 1.15 to 0.68 W/ft2 in offices and 2.32 to 0.77 W/ft2 in conference rooms 
dir = OpenStudio::Path.new("#{Dir.pwd}/measures/ReduceLPD/") # link to measure directory
measure = OpenStudio::BCLMeasure::load(dir)  # load measure
args  = OpenStudio::Ruleset::OSArgumentVector.new() # make a new argument vector
light_def = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("light_def", light_display_names) 
light_def.setValue("Bldg101_Office_LightingPowerDensity") 
args << light_def 
new_LPD_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("new_LPD_ip") 
new_LPD_ip.setValue(0.9) 
args << new_LPD_ip 
rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args) # build job from measure and args
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath()) # include its path in search tree
wf.addJob(rubyjobbuilder.toWorkItem()) # add measure to job queue

dir = OpenStudio::Path.new("#{Dir.pwd}/measures/ReduceLPD/") # link to measure directory
measure = OpenStudio::BCLMeasure::load(dir)  # load measure
args  = OpenStudio::Ruleset::OSArgumentVector.new() # make a new argument vector
light_def = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("light_def", light_display_names) 
light_def.setValue("Bldg101_Conference_LightingPowerDensity") 
args << light_def 
new_LPD_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("new_LPD_ip") 
new_LPD_ip.setValue(0.9) 
args << new_LPD_ip 
rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args) # build job from measure and args
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath()) # include its path in search tree
wf.addJob(rubyjobbuilder.toWorkItem()) # add measure to job queue
