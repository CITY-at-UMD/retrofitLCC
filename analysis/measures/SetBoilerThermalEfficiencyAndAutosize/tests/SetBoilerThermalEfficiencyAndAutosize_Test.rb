require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require "#{File.dirname(__FILE__)}/../measure.rb"

class SetBoilerThermalEfficiencyAndAutosize_Test <  MiniTest::Test

  def test_SetBoilerThermalEfficiencyAndAutosize
     
    # create an instance of the measure
    measure = SetBoilerThermalEfficiencyAndAutosize.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # load model
	translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/Bldg101_StagingPreSetback.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
	assert_equal(6, arguments.size)
    assert_equal("boiler_bool", arguments[0].name)
    assert_equal("boiler_name", arguments[1].name)
	assert_equal("boiler_thermal_efficiency", arguments[2].name)
	assert_equal("boiler_outlet_temperature_ip", arguments[3].name)
	assert_equal("is_capacity_manual", arguments[4].name)
	assert_equal("nominal_capacity_si", arguments[5].name)
       
    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    boiler_bool = arguments[0].clone
    assert(boiler_bool.setValue(false))
    argument_map["boiler_bool"] = boiler_bool
	
	boiler_name = arguments[1].clone
    assert(boiler_name.setValue("Boiler Hot Water 1"))
    argument_map["boiler_name"] = boiler_name
	
	boiler_thermal_efficiency = arguments[2].clone
    assert(boiler_thermal_efficiency.setValue(0.9))
    argument_map["boiler_thermal_efficiency"] = boiler_thermal_efficiency
	
	boiler_outlet_temperature_ip = arguments[3].clone
    assert(boiler_outlet_temperature_ip.setValue(180))
    argument_map["boiler_outlet_temperature_ip"] = boiler_outlet_temperature_ip
	
	is_capacity_manual = arguments[4].clone
    assert(is_capacity_manual.setValue(false))
    argument_map["is_capacity_manual"] = is_capacity_manual
	
	nominal_capacity_si = arguments[5].clone
    assert(nominal_capacity_si.setValue(0))
    argument_map["nominal_capacity_si"] = nominal_capacity_si

	measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")
	save_path = OpenStudio::Path.new("#{Dir.pwd}/test_out.osm")
    model.save(save_path,true)
  end  

end
