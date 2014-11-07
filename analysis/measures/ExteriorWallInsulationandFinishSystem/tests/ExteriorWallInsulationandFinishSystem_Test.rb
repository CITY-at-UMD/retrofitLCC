require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require "#{File.dirname(__FILE__)}/../measure.rb"

class ExteriorWallInsulationandFinishSystem_Test < MiniTest::Test

  def test_ExteriorWallInsulationandFinishSystem
     
    # create an instance of the measure
    measure = ExteriorWallInsulationandFinishSystem.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
   # re-load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/Bldg101_StagingPreSetback.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # refresh arguments
    arguments = measure.arguments(model)

    # set argument values to highish values and run the measure on empty model
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
		
    assert_equal(1, arguments.size)    
	insul_tchkn = arguments[0].clone
    assert(insul_tchkn.setValue(4.0))
    argument_map["insul_tchkn"] = insul_tchkn

	measure.run(model, runner, argument_map)
    result = runner.result    
    show_output(result)
    assert(result.value.valueName == "Success")
    # assert(result.info.size == 1)
    # assert(result.warnings.size == 1)
	#save_path = OpenStudio::Path.new("#{Dir.pwd}/test_out.osm")
    #model.save(save_path,true)
    
  end  

end
