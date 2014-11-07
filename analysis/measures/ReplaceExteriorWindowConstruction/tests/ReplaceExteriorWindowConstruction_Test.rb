require 'openstudio'
require 'openstudio/ruleset/ShowRunnerOutput'
require 'minitest/autorun'
require "#{File.dirname(__FILE__)}/../measure.rb"


class ReplaceExteriorWindowConstruction_Test < MiniTest::Test
  
  def test_ReplaceExteriorWindowConstruction
     
    # create an instance of the measure
    measure = ReplaceExteriorWindowConstruction.new
    
    # create an instance of a runner
    runner = OpenStudio::Ruleset::OSRunner.new
    
    # load the test model
    translator = OpenStudio::OSVersion::VersionTranslator.new
    path = OpenStudio::Path.new(File.dirname(__FILE__) + "/Bldg101_StagingPreSetback.osm")
    model = translator.loadModel(path)
    assert((not model.empty?))
    model = model.get
    
    # get arguments and test that they are what we are expecting
    arguments = measure.arguments(model)
    assert_equal(11, arguments.size)
    assert_equal("construction", arguments[0].name)
    assert((not arguments[0].hasDefaultValue))
    
    # set argument values to good values and run the measure on model with spaces
    argument_map = OpenStudio::Ruleset::OSArgumentMap.new

    count = -1

    construction = arguments[count += 1].clone
    assert(construction.setValue("Bldg101 Window with Window Film Construction"))
    argument_map["construction"] = construction

    change_fixed_windows = arguments[count += 1].clone
    assert(change_fixed_windows.setValue(true))
    argument_map["change_fixed_windows"] = change_fixed_windows

    change_operable_windows = arguments[count += 1].clone
    assert(change_operable_windows.setValue(true))
    argument_map["change_operable_windows"] = change_operable_windows

    remove_costs = arguments[count += 1].clone
    assert(remove_costs.setValue(true))
    argument_map["remove_costs"] = remove_costs

    material_cost_ip = arguments[count += 1].clone
    assert(material_cost_ip.setValue(0))
    argument_map["material_cost_ip"] = material_cost_ip

    demolition_cost_ip = arguments[count += 1].clone
    assert(demolition_cost_ip.setValue(0))
    argument_map["demolition_cost_ip"] = demolition_cost_ip

    years_until_costs_start = arguments[count += 1].clone
    assert(years_until_costs_start.setValue(0))
    argument_map["years_until_costs_start"] = years_until_costs_start

    demo_cost_initial_const = arguments[count += 1].clone
    assert(demo_cost_initial_const.setValue(false))
    argument_map["demo_cost_initial_const"] = demo_cost_initial_const

    expected_life = arguments[count += 1].clone
    assert(expected_life.setValue(20))
    argument_map["expected_life"] = expected_life

    om_cost_ip = arguments[count += 1].clone
    assert(om_cost_ip.setValue(0))
    argument_map["om_cost_ip"] = om_cost_ip

    om_frequency = arguments[count += 1].clone
    assert(om_frequency.setValue(1))
    argument_map["om_frequency"] = om_frequency
    
    measure.run(model, runner, argument_map)
    result = runner.result
    show_output(result)
    assert(result.value.valueName == "Success")	
	save_path = OpenStudio::Path.new("#{Dir.pwd}/test_out.osm")
    model.save(save_path,true)
  end

end


