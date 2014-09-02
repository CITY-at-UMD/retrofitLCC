require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class AddUtilityRates_Test < Test::Unit::TestCase
  
  def test_AddUtilityRates
  
    puts "Testing the AddUtilityRates measure...\n\n" 
    # create an instance of the measure
    measure = AddUtilityRates.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # make an empty model
    model = OpenStudio::Model::Model.new
	
    # forward translate OpenStudio Model to EnergyPlus Workspace
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    assert_equal(2, arguments.size)
    assert_equal("elec_tar", arguments[0].name)
	assert_equal("gas_tar", arguments[1].name)
       
    # set argument values to good values
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    elec_tar = arguments[0].clone
    assert(elec_tar.setValue("PECO Rates"))
    argument_map["elec_tar"] = elec_tar
	gas_tar = arguments[1].clone
    assert(gas_tar.setValue("PGW Rates"))
    argument_map["gas_tar"] = gas_tar	
	
	#idf_save_path = OpenStudio::Path.new("#{Dir.pwd}/test.idf")
	#workspace.save(idf_save_path,true)  
	
	# run the measure on the workspace
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
	assert(result.warnings.size == 0)
    #assert(result.info.size == 1)	
  
  end
  
end