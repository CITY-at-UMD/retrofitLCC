require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require "#{File.dirname(__FILE__)}/../measure.rb"

class SetBoilerCapacity_Test < MiniTest::Test

  def test_SetBoilerCapacity
    # create an instance of the measure
    measure = SetBoilerCapacity.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/Bldg101_StagingPreSetback.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
		
	# get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(3, arguments.size)
    assert_equal("boiler_bool", arguments[0].name)
	assert_equal("boiler_name", arguments[1].name)
	assert_equal("sql_fname", arguments[2].name)

    # set argument values to good values and run the measure on model
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    boiler_bool = arguments[0].clone
    assert(boiler_bool.setValue(false))
    argument_map["boiler_bool"] = boiler_bool
	
	boiler_name = arguments[1].clone
    assert(boiler_name.setValue("Boiler Hot Water 1"))
    argument_map["boiler_name"] = boiler_name
	
	file_path =  "#{Dir.pwd}/eplusout.sql"
	sql_fname = arguments[2].clone
    assert(sql_fname.setValue(file_path))
    argument_map["sql_fname"] = sql_fname
	
	measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
	save_path = OpenStudio::Path.new("#{Dir.pwd}/test_out.osm")
    model.save(save_path,true)
  end

end
