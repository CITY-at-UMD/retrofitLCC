# Reduce Space Infiltration By Percentage Measure
dir = OpenStudio::Path.new("#{Dir.pwd}/measures/ReduceSpaceInfiltrationByPercentage/") # link to measure directory
measure = OpenStudio::BCLMeasure::load(dir)  # load measure
args  = OpenStudio::Ruleset::OSArgumentVector.new() # make a new argument vector

#populate choices for argument for space types
space_type_display_names = OpenStudio::StringVector.new
space_type_display_names << "*Entire Building*"
space_type = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("space_type", space_type_display_names) 
space_type.setValue("*Entire Building*") 
args << space_type 
space_infiltration_reduction_percent = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("space_infiltration_reduction_percent") 
space_infiltration_reduction_percent.setValue(30.0) 
args << space_infiltration_reduction_percent 
material_and_installation_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_and_installation_cost") 
material_and_installation_cost.setValue(0) 
args << material_and_installation_cost 
om_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("om_cost")
om_cost.setValue(0.0)
args << om_cost
om_frequency = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("om_frequency")
om_frequency.setValue(1)
args << om_frequency

rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args) # build job from measure and args
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath()) # include its path in search tree
wf.addJob(rubyjobbuilder.toWorkItem()) # add measure to job queue
