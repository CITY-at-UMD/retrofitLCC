require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require_relative '../measure.rb'
require 'fileutils'
require "#{File.dirname(__FILE__)}/../measure.rb"

name = "COIL COOLING DX TWO SPEED 1"
LS_AFR = "DESIGN SIZE RATED LOW SPEED AIR FLOW RATE"
HS_CAP = "DESIGN SIZE RATED HIGH SPEED TOTAL COOLING CAPACITY"
HS_SHR = "DESIGN SIZE RATED HIGH SPEED SENSIBLE HEAT RATIO"
HS_AFR = "DESIGN SIZE RATED HIGH SPEED AIR FLOW RATE"
LS_CAP = "DESIGN SIZE RATED LOW SPEED TOTAL COOLING CAPACITY"
LS_SHR = "DESIGN SIZE RATED LOW SPEED SENSIBLE HEAT RATIO"
LS_AFR = "DESIGN SIZE RATED LOW SPEED AIR FLOW RATE"

class HardsizeTwoSpeedDXCoolingCoilTest < MiniTest::Test

  # def setup
  # end

  # def teardown
  # end

  def test_number_of_arguments_and_argument_names
    # create an instance of the measure
    measure = HardsizeTwoSpeedDXCoolingCoil.new

    # make an empty model
    model = OpenStudio::Model::Model.new

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(2, arguments.size)
    assert_equal("object", arguments[0].name)
	assert_equal("eio_fname", arguments[1].name)	
  end


  def test_good_argument_values
    # create an instance of the measure
    measure = HardsizeTwoSpeedDXCoolingCoil.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

	# get model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/Bldg101_StagingPreSetback.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
	
	# get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(2, arguments.size)
    assert_equal("object", arguments[0].name)
	assert_equal("eio_fname", arguments[1].name)
    
    # set argument values to good values and run the measure on model
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    object = arguments[0].clone
    assert(object.setValue("*All Air Loops*"))
    argument_map["object"] = object	

	file_path =  "#{Dir.pwd}/eplusout.eio"
	eio_fname = arguments[1].clone
    assert(eio_fname.setValue(file_path))
    argument_map["eio_fname"] = eio_fname
	
	measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert_equal("Success", result.value.valueName)
	save_path = OpenStudio::Path.new("#{Dir.pwd}/test_out.osm")
    model.save(save_path,true)
  end

end
