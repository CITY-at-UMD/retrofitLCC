require 'openstudio'

require 'openstudio/ruleset/ShowRunnerOutput'

require "#{File.dirname(__FILE__)}/../measure.rb"

require 'test/unit'

class AedgSmallToMediumOfficeExteriorWallConstruction_Test < Test::Unit::TestCase


  def test_AedgSmallToMediumOfficeExteriorWallConstruction

    # create an instance of the measure
    measure = AedgSmallToMediumOfficeExteriorWallConstruction.new

    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new

    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/0209_SimpleSchool_c_123_dev.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get

    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(1, arguments.size)
    assert_equal("material_cost_insulation_increase_ip", arguments[0].name)

    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new
    material_cost_insulation_increase_ip = arguments[0].clone
    assert(material_cost_insulation_increase_ip.setValue(5.0))
    argument_map["material_cost_insulation_increase_ip"] = material_cost_insulation_increase_ip
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    #assert(result.value.valueName == "Success")
    #assert(result.warnings.size == 0)
    #assert(result.info.size == 0)

  end

end
