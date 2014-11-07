require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require "#{File.dirname(__FILE__)}/../measure.rb"

class ReduceLPD_Test < MiniTest::Test
  def test_ReduceLPD
    # create an instance of the measure
    measure = ReduceLPD.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/Bldg101_StagingPreSetback.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(2, arguments.size)
    assert_equal("light_def", arguments[0].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    light_def = arguments[0].clone
    assert(light_def.setValue("Bldg101_Office_LightingPowerDensity"))
    argument_map["light_def"] = light_def

    new_LPD_ip = arguments[1].clone
    assert(new_LPD_ip.setValue(0.9))
    argument_map["new_LPD_ip"] = new_LPD_ip

    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 1)
    #assert(result.info.size == 2)
	
	#save_path = OpenStudio::Path.new("#{Dir.pwd}/test_out.osm")
    #model.save(save_path,true)

  end

end
