# SetBoilerThermalEfficiencyAndAutosize measure
dir = OpenStudio::Path.new("#{Dir.pwd}/measures/SetBoilerThermalEfficiencyAndAutosize/") # link to measure directory
measure = OpenStudio::BCLMeasure::load(dir)  # load measure
args  = OpenStudio::Ruleset::OSArgumentVector.new() # make a new argument vector

boiler_bool = OpenStudio::Ruleset::OSArgument::makeBoolArgument("boiler_bool")
boiler_bool.setValue(false)
args << boiler_bool

boiler_display_names = OpenStudio::StringVector.new
boiler_display_names << ''
boiler_display_names << 'Boiler Hot Water 1'
boiler_name = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("boiler_name", boiler_display_names)
boiler_name.setValue("Boiler Hot Water 1")
args << boiler_name

boiler_thermal_efficiency = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boiler_thermal_efficiency")
boiler_thermal_efficiency.setValue(0.9)
args << boiler_thermal_efficiency

boiler_outlet_temperature_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("boiler_outlet_temperature_ip")
boiler_outlet_temperature_ip.setValue(140)
args << boiler_outlet_temperature_ip

is_capacity_manual = OpenStudio::Ruleset::OSArgument::makeBoolArgument("is_capacity_manual")
is_capacity_manual.setValue(false)
args << is_capacity_manual

nominal_capacity_si = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("nominal_capacity_si")
nominal_capacity_si.setValue(0)
args << nominal_capacity_si

rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args) # build job from measure and args
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath()) # include its path in search tree
wf.addJob(rubyjobbuilder.toWorkItem()) # add measure to job queue