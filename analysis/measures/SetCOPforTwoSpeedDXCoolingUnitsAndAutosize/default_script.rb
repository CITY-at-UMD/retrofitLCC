# SetCOPforTwoSpeedDXCoolingUnitsAndAutosize measure
dir = OpenStudio::Path.new("#{Dir.pwd}/measures/SetCOPforTwoSpeedDXCoolingUnitsAndAutosize/") # link to measure directory
measure = OpenStudio::BCLMeasure::load(dir)  # load measure
args  = OpenStudio::Ruleset::OSArgumentVector.new() # make a new argument vector

air_loop_display_names = OpenStudio::StringVector.new
air_loop_display_names << "*All Air Loops*"

object = OpenStudio::Ruleset::OSArgument::makeChoiceArgument("object", air_loop_display_names)
object.setValue("*All Air Loops*") 
args << object
cop_high = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cop_high",true)
cop_high.setValue(3.37)
args << cop_high
cop_low = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("cop_low",true)
cop_low.setValue(4.75)
args << cop_low
remove_costs = OpenStudio::Ruleset::OSArgument::makeBoolArgument("remove_costs",true)
remove_costs.setValue(true)
args << remove_costs
material_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("material_cost",true)
material_cost.setValue(0.0)
args << material_cost
demolition_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("demolition_cost",true)
demolition_cost.setValue(0.0)
args << demolition_cost
years_until_costs_start = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("years_until_costs_start",true)
years_until_costs_start.setValue(0)
args << years_until_costs_start
demo_cost_initial_const = OpenStudio::Ruleset::OSArgument::makeBoolArgument("demo_cost_initial_const",true)
demo_cost_initial_const.setValue(false)
args << demo_cost_initial_const
expected_life = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("expected_life",true)
expected_life.setValue(20)
args << expected_life
om_cost = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("om_cost",true)   
om_cost.setValue(0.0)
args << om_cost
om_frequency = OpenStudio::Ruleset::OSArgument::makeIntegerArgument("om_frequency",true)
om_frequency.setValue(1)
args << om_frequency

rubyjobbuilder = OpenStudio::Runmanager::RubyJobBuilder.new(measure.get(), args) # build job from measure and args
rubyjobbuilder.setIncludeDir(OpenStudio::getOpenStudioRubyIncludePath()) # include its path in search tree
wf.addJob(rubyjobbuilder.toWorkItem()) # add measure to job queue

