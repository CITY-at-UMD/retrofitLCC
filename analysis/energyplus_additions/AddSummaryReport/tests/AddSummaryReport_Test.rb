require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class AddSummaryReport_Test < Test::Unit::TestCase
  
  def test_AddSummaryReport
     
	#puts "Testing the AddSummaryReport measure...\n\n" 
    # create an instance of the measure
    measure = AddSummaryReport.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # make an empty model
    model = OpenStudio::Model::Model.new
	
    # forward translate OpenStudio Model to EnergyPlus Workspace
    ft = OpenStudio::EnergyPlus::ForwardTranslator.new
    workspace = ft.translateModel(model)
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(workspace)
    assert_equal(1, arguments.size)
    assert_equal("reports_request", arguments[0].name)
       
    # set argument values to good values
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    reports_request = arguments[0].clone
    assert(reports_request.setValue("ZoneComponentLoadSummary"))
    argument_map["reports_request"] = reports_request
	
	# run the measure on the workspace
    measure.run(workspace, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
	assert(result.warnings.size == 0)
    #assert(result.info.size == 1)
	
	#idf_save_path = OpenStudio::Path.new("#{Dir.pwd}/test.idf")
	#workspace.save(idf_save_path,true)
	
  end

end