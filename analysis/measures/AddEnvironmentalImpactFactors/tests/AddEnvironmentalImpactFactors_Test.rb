require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class AddEnvironmentalImpactFactors_Test < Test::Unit::TestCase
  
  def test_AddEnvironmentalImpactFactors
     
	puts "testing the EnvironmentalImpactFactors measure" 
    # create an instance of the measure
    measure = AddEnvironmentalImpactFactors.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # make an empty model
    model = OpenStudio::Model::Model.new
	
    # forward translate OpenStudio Model to EnergyPlus Workspace
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    assert_equal(3, arguments.size)
    assert_equal("reporting_frequency", arguments[0].name)
	assert_equal("electricity_region", arguments[1].name)
	assert_equal("equipment", arguments[2].name)
       
    # set argument values to good values
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    reporting_frequency = arguments[0].clone
    assert(reporting_frequency.setValue("RunPeriod"))
    argument_map["reporting_frequency"] = reporting_frequency
	electricity_region = arguments[1].clone
	assert(electricity_region.setValue("National"))
    argument_map["electricity_region"] = electricity_region
	equipment = arguments[2].clone
	assert(equipment.setValue("Commercial Boiler"))
    argument_map["equipment"] = equipment
	
	# run the measure on the workspace
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
	assert(result.warnings.size == 0)
    #assert(result.info.size == 1)
	
  end

end