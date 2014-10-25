# Occupancy Sensors Measure
# In offices, conference rooms, and bathrooms, reduce lighting fraction from 0.2 to 0.05 during unoccupied hours on weekdays, and 0.15 to 0.05 on weekends.  

# Bldg101_Office_LightingPowerDensity 
dir = OpenStudio::Path.new("#{Dir.pwd}/measures/ReduceNightTimeLightingLoads/"); # link to measure directory
measure = OpenStudio::BCLMeasure::load(dir);  # load measure
args  = OpenStudio::Ruleset::OSArgumentVector.new(); # make a new argument vector
lights_def = OpenStudio::Ruleset::OSArgument::makeStringArgument("lights_def"); #make an argument for lights definition
lights_def.setValue("Bldg101_Office_LightingPowerDensity") 
args << lights_def 
fraction_value = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fraction_value",true)	#make an argument for fractional value during specified time
fraction_value.setValue(0.05)
args << fraction_value
apply_weekday = OpenStudio::Ruleset::OSArgument::makeBoolArgument("apply_weekday",true)	#apply to weekday
apply_weekday.setValue(true)
args << apply_weekday
start_weekday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("start_weekday",true)	#weekday start time
start_weekday.setValue(22.0)
args << start_weekday
end_weekday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("end_weekday",true)	#weekday end time
end_weekday.setValue(7.0)
args << end_weekday
apply_saturday = OpenStudio::Ruleset::OSArgument::makeBoolArgument("apply_saturday",true)	#apply to saturday
apply_saturday.setValue(true)
args << apply_saturday
start_saturday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("start_saturday",true)	 #saturday start time
start_saturday.setValue(0.0)
args << start_saturday
end_saturday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("end_saturday",true)	#saturday end time
end_saturday.setValue(0.0)
args << end_saturday
apply_sunday = OpenStudio::Ruleset::OSArgument::makeBoolArgument("apply_sunday",true)	#apply to sunday
apply_sunday.setValue(true)
args << apply_sunday
start_sunday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("start_sunday",true)	#sunday start time
start_sunday.setValue(0.0)
args << start_sunday
end_sunday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("end_sunday",true)	#sunday end time
end_sunday.setValue(0.0)
args << end_sunday
material_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost",true)	#make an argument for material and installation cost
material_cost.setValue(0.0)
args << material_cost
years_until_costs_start = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("years_until_costs_start",true)	#make an argument for duration in years until costs start
years_until_costs_start.setValue(0)
args << years_until_costs_start
expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life",true)	#make an argument for expected life
expected_life.setValue(20)
args << expected_life
om_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("om_cost",true)	#make an argument for o&m cost
om_cost.setValue(0.0)
args << om_cost
om_frequency = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("om_frequency",true)	#make an argument for o&m frequency
om_frequency.setValue(1)
args << om_frequency
rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args); # build job from measure and args
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath()); # include its path in search tree
wf.addJob(rubyjobbuilder.toWorkItem()); # add measure to job queue

#Bldg101_Conference_LightingPowerDensity
dir = OpenStudio::Path.new("#{Dir.pwd}/measures/ReduceNightTimeLightingLoads/"); # link to measure directory
measure = OpenStudio::BCLMeasure::load(dir);  # load measure
args  = OpenStudio::Ruleset::OSArgumentVector.new(); # make a new argument vector
lights_def = OpenStudio::Ruleset::OSArgument::makeStringArgument("lights_def"); #make an argument for lights definition
lights_def.setValue("Bldg101_Conference_LightingPowerDensity") 
args << lights_def 
fraction_value = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fraction_value",true)	#make an argument for fractional value during specified time
fraction_value.setValue(0.05)
args << fraction_value
apply_weekday = OpenStudio::Ruleset::OSArgument::makeBoolArgument("apply_weekday",true)	#apply to weekday
apply_weekday.setValue(true)
args << apply_weekday
start_weekday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("start_weekday",true)	#weekday start time
start_weekday.setValue(22.0)
args << start_weekday
end_weekday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("end_weekday",true)	#weekday end time
end_weekday.setValue(7.0)
args << end_weekday
apply_saturday = OpenStudio::Ruleset::OSArgument::makeBoolArgument("apply_saturday",true)	#apply to saturday
apply_saturday.setValue(true)
args << apply_saturday
start_saturday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("start_saturday",true)	 #saturday start time
start_saturday.setValue(0.0)
args << start_saturday
end_saturday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("end_saturday",true)	#saturday end time
end_saturday.setValue(0.0)
args << end_saturday
apply_sunday = OpenStudio::Ruleset::OSArgument::makeBoolArgument("apply_sunday",true)	#apply to sunday
apply_sunday.setValue(true)
args << apply_sunday
start_sunday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("start_sunday",true)	#sunday start time
start_sunday.setValue(0.0)
args << start_sunday
end_sunday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("end_sunday",true)	#sunday end time
end_sunday.setValue(0.0)
args << end_sunday
material_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost",true)	#make an argument for material and installation cost
material_cost.setValue(0.0)
args << material_cost
years_until_costs_start = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("years_until_costs_start",true)	#make an argument for duration in years until costs start
years_until_costs_start.setValue(0)
args << years_until_costs_start
expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life",true)	#make an argument for expected life
expected_life.setValue(20)
args << expected_life
om_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("om_cost",true)	#make an argument for o&m cost
om_cost.setValue(0.0)
args << om_cost
om_frequency = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("om_frequency",true)	#make an argument for o&m frequency
om_frequency.setValue(1)
args << om_frequency
rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args); # build job from measure and args
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath()); # include its path in search tree
wf.addJob(rubyjobbuilder.toWorkItem()); # add measure to job queue

#Bldg101_Bathroom_LightingPowerDensity
dir = OpenStudio::Path.new("#{Dir.pwd}/measures/ReduceNightTimeLightingLoads/"); # link to measure directory
measure = OpenStudio::BCLMeasure::load(dir);  # load measure
args  = OpenStudio::Ruleset::OSArgumentVector.new(); # make a new argument vector
lights_def = OpenStudio::Ruleset::OSArgument::makeStringArgument("lights_def"); #make an argument for lights definition
lights_def.setValue("Bldg101_Bathroom_LightingPowerDensity") 
args << lights_def 
fraction_value = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("fraction_value",true)	#make an argument for fractional value during specified time
fraction_value.setValue(0.05)
args << fraction_value
apply_weekday = OpenStudio::Ruleset::OSArgument::makeBoolArgument("apply_weekday",true)	#apply to weekday
apply_weekday.setValue(true)
args << apply_weekday
start_weekday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("start_weekday",true)	#weekday start time
start_weekday.setValue(22.0)
args << start_weekday
end_weekday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("end_weekday",true)	#weekday end time
end_weekday.setValue(7.0)
args << end_weekday
apply_saturday = OpenStudio::Ruleset::OSArgument::makeBoolArgument("apply_saturday",true)	#apply to saturday
apply_saturday.setValue(true)
args << apply_saturday
start_saturday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("start_saturday",true)	 #saturday start time
start_saturday.setValue(0.0)
args << start_saturday
end_saturday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("end_saturday",true)	#saturday end time
end_saturday.setValue(0.0)
args << end_saturday
apply_sunday = OpenStudio::Ruleset::OSArgument::makeBoolArgument("apply_sunday",true)	#apply to sunday
apply_sunday.setValue(true)
args << apply_sunday
start_sunday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("start_sunday",true)	#sunday start time
start_sunday.setValue(0.0)
args << start_sunday
end_sunday = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("end_sunday",true)	#sunday end time
end_sunday.setValue(0.0)
args << end_sunday
material_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost",true)	#make an argument for material and installation cost
material_cost.setValue(0.0)
args << material_cost
years_until_costs_start = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("years_until_costs_start",true)	#make an argument for duration in years until costs start
years_until_costs_start.setValue(0)
args << years_until_costs_start
expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life",true)	#make an argument for expected life
expected_life.setValue(20)
args << expected_life
om_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("om_cost",true)	#make an argument for o&m cost
om_cost.setValue(0.0)
args << om_cost
om_frequency = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("om_frequency",true)	#make an argument for o&m frequency
om_frequency.setValue(1)
args << om_frequency
rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args); # build job from measure and args
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath()); # include its path in search tree
wf.addJob(rubyjobbuilder.toWorkItem()); # add measure to job queue