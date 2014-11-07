# Replace exterior window construction measure

#populate choices for argument for constructions
construction_display_names = OpenStudio::StringVector.new
construction_display_names << ''
construction_display_names << 'Bldg101 Window with Window Film Construction'

dir = OpenStudio::Path.new("#{Dir.pwd}/measures/ReplaceExteriorWindowConstruction/") # link to measure directory
measure = OpenStudio::BCLMeasure::load(dir)  # load measure
args  = OpenStudio::Ruleset::OSArgumentVector.new() # make a new argument vector
construction = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("construction", construction_display_names) 
construction.setValue("Bldg101 Window with Window Film Construction") 
args << construction 
change_fixed_windows = OpenStudio::Ruleset::OSArgument::makeBoolArgument("change_fixed_windows") 
change_fixed_windows.setValue(true) 
args << change_fixed_windows 
change_operable_windows = OpenStudio::Ruleset::OSArgument::makeBoolArgument("change_operable_windows") 
change_operable_windows.setValue(true) 
args << change_operable_windows 
material_cost_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost_ip") 
material_cost_ip.setValue(0) 
args << material_cost_ip 
demolition_cost_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("demolition_cost_ip") 
demolition_cost_ip.setValue(0) 
args << demolition_cost_ip 
years_until_costs_start = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("years_until_costs_start") 
years_until_costs_start.setValue(0) 
args << years_until_costs_start 
demo_cost_initial_const = OpenStudio::Ruleset::OSArgument::makeBoolArgument("demo_cost_initial_const")
demo_cost_initial_const.setValue(false)
args << demo_cost_initial_const
expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life")
expected_life.setValue(20)
args << expected_life
om_cost_ip = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("om_cost_ip")
om_cost_ip.setValue(0.0)
args << om_cost_ip
om_frequency = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("om_frequency")
om_frequency.setValue(1)
args << om_frequency

rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args) # build job from measure and args
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath()) # include its path in search tree
wf.addJob(rubyjobbuilder.toWorkItem()) # add measure to job queue
