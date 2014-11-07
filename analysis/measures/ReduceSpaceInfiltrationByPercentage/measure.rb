#see the URL below for information on how to write OpenStudio measures
# http://openstudio.nrel.gov/openstudio-measure-writing-guide

#see the URL below for information on using life cycle cost objects in OpenStudio
# http://openstudio.nrel.gov/openstudio-life-cycle-examples

#see the URL below for access to C++ documentation on model objects (click on "model" in the main window to view model objects)
# http://openstudio.nrel.gov/sites/openstudio.nrel.gov/files/nv_data/cpp_documentation_it/model/html/namespaces.html

include OpenStudio::Ruleset

#start the measure
class ReduceSpaceInfiltrationByPercentage < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ReduceSpaceInfiltrationByPercentage"
  end

  #define the arguments that the user will input
  def arguments(model)
    args = OSArgumentVector.new

    #make a choice argument for model objects
    space_type_handles = OpenStudio::StringVector.new
    space_type_display_names = OpenStudio::StringVector.new

    #putting model object and names into hash
    space_type_args = model.getSpaceTypes
    space_type_args_hash = {}
    space_type_args.each do |space_type_arg|
      space_type_args_hash[space_type_arg.name.to_s] = space_type_arg
    end

    #looping through sorted hash of model objects
    space_type_args_hash.sort.map do |key,value|
      #only include if space type is used in the model
      if value.spaces.size > 0
        space_type_handles << value.handle.to_s
        space_type_display_names << key
      end
    end

    #add building to string vector with space type
    building = model.getBuilding
    space_type_handles << building.handle.to_s
    space_type_display_names << "*Entire Building*"

    #make a choice argument for space type
    space_type = OSArgument::makeChoiceArgument("space_type", 
                                                space_type_handles, 
                                                space_type_display_names)
    space_type.setDisplayName("Apply the Measure to a specific Space Type or to the Entire Model.")
    #if no space type is chosen this will run on the entire building
    space_type.setDefaultValue("*Entire Building*") 
    args << space_type

    #make an argument for reduction percentage
    space_infiltration_reduction_percent = OSArgument::makeDoubleArgument(
        "space_infiltration_reduction_percent",
        true)
    space_infiltration_reduction_percent.setDisplayName("Space Infiltration Reduction (%).")
    space_infiltration_reduction_percent.setDefaultValue(30.0)
    args << space_infiltration_reduction_percent

    #make an argument for material and installation cost
    material_and_installation_cost = OSArgument::makeDoubleArgument(
        "material_and_installation_cost",
        true)
    material_and_installation_cost.setDisplayName("Increase in Material and Installation Costs " + 
                                                  "for Building per Affected Floor Area ($/ft^2).")
    material_and_installation_cost.setDefaultValue(0.0)
    args << material_and_installation_cost

    #make an argument for O & M cost
    om_cost = OSArgument::makeDoubleArgument("om_cost",true)
    om_cost.setDisplayName("O & M Costs for Construction per Affected Floor Area ($/ft^2).")
    om_cost.setDefaultValue(0.0)
    args << om_cost

    #make an argument for O & M frequency
    om_frequency = OSArgument::makeIntegerArgument("om_frequency",true)
    om_frequency.setDisplayName("O & M Frequency (whole years).")
    om_frequency.setDefaultValue(1)
    args << om_frequency

    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)

    #use the built-in error checking
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    os_version = OpenStudio::VersionString.new(OpenStudio::openStudioVersion())
    min_version_feature1 = OpenStudio::VersionString.new("1.2.2")
    min_version_feature2 = OpenStudio::VersionString.new("1.2.3")

    #assign the user inputs to variables
    object = runner.getOptionalWorkspaceObjectChoiceValue("space_type",user_arguments,model)
    space_infiltration_reduction_percent = runner.getDoubleArgumentValue(
        "space_infiltration_reduction_percent",
        user_arguments)
    material_and_installation_cost = runner.getDoubleArgumentValue(
        "material_and_installation_cost",
        user_arguments)
    om_cost = runner.getDoubleArgumentValue("om_cost",user_arguments)
    om_frequency = runner.getIntegerArgumentValue("om_frequency",user_arguments)

    #see if measure should run on space type or on the entire building
    #if the former, check the space_type for reasonableness
    apply_to_building = false
    space_type = nil
    if object.empty?
      handle = runner.getStringArgumentValue("space_type",user_arguments)
      if handle.empty?
        runner.registerError("No space type was chosen.")
      else
        runner.registerError("The selected space type with handle '#{handle}' was not found " + 
                             "in the model. It may have been removed by another measure.")
      end
      return false
    else
      if not object.get.to_SpaceType.empty?
        space_type = object.get.to_SpaceType.get
      elsif not object.get.to_Building.empty?
        apply_to_building = true
      else
        runner.registerError("Script Error - argument not showing up as space type or building.")
        return false
      end
    end

    if os_version >= min_version_feature1
      runner.registerValue("space_type_name",space_type.name.get) if space_type
      runner.registerValue("apply_to_building",apply_to_building)
    end

    #check the space_infiltration_reduction_percent and for reasonableness
    if space_infiltration_reduction_percent > 100
      runner.registerError("Please enter a value less than or equal to 100 for the Space " + 
                           "Infiltration reduction percentage.")
      return false
    elsif space_infiltration_reduction_percent == 0
      runner.registerInfo("No Space Infiltration adjustment requested, but some life cycle " + 
                          "costs may still be affected.")
    elsif space_infiltration_reduction_percent < 1 and space_infiltration_reduction_percent > -1
      runner.registerWarning("A Space Infiltration reduction percentage of " + 
                             "#{space_infiltration_reduction_percent} percent is abnormally low.")
    elsif space_infiltration_reduction_percent > 90
      runner.registerWarning("A Space Infiltration reduction percentage of " + 
                             "#{space_infiltration_reduction_percent} percent is abnormally high.")
    elsif space_infiltration_reduction_percent < 0
      runner.registerInfo("The requested value for Space Infiltration reduction percentage was " + 
                          "negative. This will result in an increase in Space Infiltration.")
    end

    #check lifecycle cost arguments for reasonableness
    if material_and_installation_cost < -100
      runner.registerError("Material and Installation Cost percentage increase can't be less " + 
                           "than -100.")
      return false
    end

    if om_cost < -100
      runner.registerError("O & M Cost percentage increase can't be less than -100.")
      return false
    end

    if om_frequency < 1
      runner.registerError("Choose an integer greater than 0 for O & M Frequency.")
    end

    #report on extent of change: number of infiltration objects and floor area
    #report on magnitude of change: infiltration amounts before and after
    building = model.building.get
    total_num_infiltration_objects = model.getSpaceInfiltrationDesignFlowRates.size
    total_floor_area_si = building.floorArea
    # calculate and report no matter what
    num_altered_infiltration_objects = 0
    affected_floor_area_si = 0.0
    # calculate and report if OS version recent enough
    infiltration_design_flow_rate_before = nil
    infiltration_design_flow_rate_after = nil
    infiltration_flow_floor_area_before = nil
    infiltration_flow_floor_area_after = nil
    infiltration_flow_ext_area_before = nil
    infiltration_flow_ext_area_after = nil
    infiltration_flow_ext_wall_area_before = nil
    infiltration_flow_ext_wall_area_after = nil
    infiltration_ach_before = nil
    infiltration_ach_after = nil

    #get space types and spaces whose infiltration objects should be modified
    infiltration_objects_to_modify = []
    if apply_to_building
      building = model.building.get
      # only get infiltration objects that are actually used
      model.getSpaceTypes.each { |space_type|
        next if space_type.spaces.size == 0
        space_type.spaceInfiltrationDesignFlowRates.each { |st_infil|
          infiltration_objects_to_modify << st_infil
        }
      }
      model.getSpaces.each { |space|
        space.spaceInfiltrationDesignFlowRates.each { |space_infil|
          infiltration_objects_to_modify << space_infil
        }
      }
      affected_floor_area_si = building.floorArea
      if os_version >= min_version_feature1
        infiltration_design_flow_rate_before = building.infiltrationDesignFlowRate
        infiltration_flow_floor_area_before = building.infiltrationDesignFlowPerSpaceFloorArea
        infiltration_flow_ext_area_before = building.infiltrationDesignFlowPerExteriorSurfaceArea
        infiltration_flow_ext_wall_area_before = building.infiltrationDesignFlowPerExteriorWallArea
        infiltration_ach_before = building.infiltrationDesignAirChangesPerHour
      end
    else
      space_type.spaceInfiltrationDesignFlowRates.each { |st_infil|
        infiltration_objects_to_modify << st_infil
      }
      if os_version >= min_version_feature1
        infiltration_design_flow_rate_before = 0.0
        infiltration_flow_floor_area_before = 0.0
        infiltration_flow_ext_area_before = 0.0
        infiltration_flow_ext_wall_area_before = 0.0
        infiltration_ach_before = 0.0
      end
      space_type.spaces.each { |space|
        space.spaceInfiltrationDesignFlowRates.each { |space_infil|
          infiltration_objects_to_modify << space_infil
        }
        if os_version >= min_version_feature1
          infiltration_design_flow_rate_before += space.infiltrationDesignFlowRate
          infiltration_flow_floor_area_before += space.infiltrationDesignFlowPerSpaceFloorArea
          infiltration_flow_ext_area_before += space.infiltrationDesignFlowPerExteriorSurfaceArea
          infiltration_flow_ext_wall_area_before += space.infiltrationDesignFlowPerExteriorWallArea
          infiltration_ach_before += space.infiltrationDesignAirChangesPerHour
        end
      }
      affected_floor_area_si = space_type.floorArea
    end
    num_altered_infiltration_objects = infiltration_objects_to_modify.size

    #report initial condition of model
    #report text in IP
    #report machine values in SI
    total_floor_area_ip = OpenStudio::convert(total_floor_area_si,"m^2","ft^2").get
    affected_floor_area_ip = OpenStudio::convert(affected_floor_area_si,"m^2","ft^2").get
    if os_version >= min_version_feature1
      runner.registerValue("total_num_infiltration_objects",total_num_infiltration_objects)
      runner.registerValue("total_floor_area",total_floor_area_si,"m^2")
      runner.registerValue("num_altered_infiltration_objects",num_altered_infiltration_objects)
      runner.registerValue("affected_floor_area",affected_floor_area_si,"m^2")
      runner.registerValue("infiltration_design_flow_rate_before",
                           infiltration_design_flow_rate_before,
                           "m^3/s")
      runner.registerValue("infiltration_flow_floor_area_before",
                           infiltration_flow_floor_area_before,
                           "m^3/s*m^2")
      runner.registerValue("infiltration_flow_ext_area_before",
                           infiltration_flow_ext_area_before,
                           "m^3/s*m^2")
      runner.registerValue("infiltration_flow_ext_wall_area_before",
                           infiltration_flow_ext_wall_area_before,
                           "m^3/s*m^2")
      runner.registerValue("infiltration_ach_before",
                           infiltration_ach_before,
                           "1/h")
    end
    if os_version >= min_version_feature2
      runner.registerInitialCondition("The initial model contains #{total_num_infiltration_objects} " + 
          "space infiltration objects and a floor area of " + 
          "#{OpenStudio::toNeatString(total_floor_area_ip,0)} ft^2. " + 
          "#{num_altered_infiltration_objects} space infiltration objects affecting " + 
          "#{OpenStudio::toNeatString(affected_floor_area_ip,0)} ft^2 are to be " + 
          "modified. Over the affected area, the current infiltration level is " + 
          "#{OpenStudio::toNeatStringBySigFigs(infiltration_ach_before,3)} ACH.");
    else          
      runner.registerInitialCondition("The initial model contains #{total_num_infiltration_objects} " + 
                                      "space infiltration objects and a floor area of " + 
                                      "#{total_floor_area_ip} ft^2. " + 
                                      "#{num_altered_infiltration_objects} space infiltration " + 
                                      "objects affecting #{affected_floor_area_ip} ft^2 " +
                                      "are to be modified.");
    end

    if num_altered_infiltration_objects == 0 and material_and_installation_cost == 0 and om_cost == 0
      runner.registerAsNotApplicable("No space infiltration objects were found in the specified space type(s) and no life cycle costs were requested.")
      return true # make sure we don't actually do anything
    end

    #def to alter performance and life cycle costs of objects
    def alter_performance(object, space_infiltration_reduction_percent, runner)

      #edit instance based on percentage reduction
      instance = object
      ok = false
      new_as_fraction_of_old = (1.0 - space_infiltration_reduction_percent/100.0)
      if not instance.designFlowRate.empty?
        new_infiltration_design_flow_rate = instance.designFlowRate.get * new_as_fraction_of_old
        ok = instance.setDesignFlowRate(new_infiltration_design_flow_rate)
      elsif not instance.flowperSpaceFloorArea.empty?
        new_infiltration_flow_floor_area = instance.flowperSpaceFloorArea.get * new_as_fraction_of_old
        ok = instance.setFlowperSpaceFloorArea(new_infiltration_flow_floor_area)
      elsif not instance.flowperExteriorSurfaceArea.empty?
        new_infiltration_flow_ext_area = instance.flowperExteriorSurfaceArea.get * new_as_fraction_of_old
        ok = instance.setFlowperExteriorSurfaceArea(new_infiltration_flow_ext_area)
      elsif not instance.flowperExteriorWallArea.empty?
        new_infiltration_flow_ext_wall_area = instance.flowperExteriorWallArea.get * new_as_fraction_of_old
        ok = instance.setFlowperExteriorWallArea(new_infiltration_flow_ext_wall_area)
      elsif not instance.airChangesperHour.empty?
        new_infiltration_ach = instance.airChangesperHour.get * new_as_fraction_of_old
        ok = instance.setAirChangesperHour(new_infiltration_ach)
      else
        runner.registerWarning("'#{instance.name}' is used by one or more instances and has no load values.")
      end

      if not ok
        runner.registerWarning("Attempt to reduce infiltration in #{instance.briefDescription} " + 
            "by #{space_infiltration_reduction_percent}% failed.")
      end

    end #end of def alter_performance_and_lcc()

    #loop through space types and spaces
    infiltration_objects_to_modify.each do |infil_object|
      
      #call def to alter performance
      alter_performance(infil_object, space_infiltration_reduction_percent, runner)

      #rename
      updated_instance_name = infil_object.setName(
          "#{infil_object.name} #{space_infiltration_reduction_percent} percent reduction")

    end #end space types each do

    #only add LifeCyleCostItem if the user entered some non 0 cost values
    if material_and_installation_cost != 0 or om_cost != 0
      lcc_mat = OpenStudio::Model::LifeCycleCost.createLifeCycleCost(
                    "LCC_Mat - Cost to Adjust Infiltration", 
                    building, 
                    affected_floor_area_ip * material_and_installation_cost, 
                    "CostPerEach", 
                    "Construction", 
                    0, 
                    0)  #0 for expected life will result infinite expected life
      lcc_om = OpenStudio::Model::LifeCycleCost.createLifeCycleCost(
                   "LCC_OM - Cost to Adjust Infiltration", 
                   building, 
                   affected_floor_area_ip * om_cost, 
                   "CostPerEach", 
                   "Maintenance", 
                   om_frequency, 
                   0) #o&m costs start after at sane time that material and installation costs occur
      runner.registerInfo("Costs related to the change in infiltration are attached to the " + 
                          "building object.  Any subsequent measures that may affect infiltration " + 
                          "won't affect these costs.")
      final_cost = lcc_mat.get.totalCost
    else
      runner.registerInfo("Cost arguments were not provided, no cost objects were added to the model.")
      final_cost = 0
    end #end of material_cost_ip != 0 or om_cost_ip != 0


    #report final condition
    if os_version >= min_version_feature1
      if apply_to_building
        infiltration_design_flow_rate_after = building.infiltrationDesignFlowRate
        infiltration_flow_floor_area_after = building.infiltrationDesignFlowPerSpaceFloorArea
        infiltration_flow_ext_area_after = building.infiltrationDesignFlowPerExteriorSurfaceArea
        infiltration_flow_ext_wall_area_after = building.infiltrationDesignFlowPerExteriorWallArea
        infiltration_ach_after = building.infiltrationDesignAirChangesPerHour
      else
        infiltration_design_flow_rate_after = 0.0
        infiltration_flow_floor_area_after = 0.0
        infiltration_flow_ext_area_after = 0.0
        infiltration_flow_ext_wall_area_after = 0.0
        infiltration_ach_after = 0.0
        space_type.spaces.each { |space|
          infiltration_design_flow_rate_after += space.infiltrationDesignFlowRate
          infiltration_flow_floor_area_after += space.infiltrationDesignFlowPerSpaceFloorArea
          infiltration_flow_ext_area_after += space.infiltrationDesignFlowPerExteriorSurfaceArea
          infiltration_flow_ext_wall_area_after += space.infiltrationDesignFlowPerExteriorWallArea
          infiltration_ach_after += space.infiltrationDesignAirChangesPerHour
        }
      end
      runner.registerValue("infiltration_design_flow_rate_after",
                           infiltration_design_flow_rate_after,
                           "m^3/s")
      runner.registerValue("infiltration_flow_floor_area_after",
                           infiltration_flow_floor_area_after,
                           "m^3/s*m^2")
      runner.registerValue("infiltration_flow_ext_area_after",
                           infiltration_flow_ext_area_after,
                           "m^3/s*m^2")
      runner.registerValue("infiltration_flow_ext_wall_area_after",
                           infiltration_flow_ext_wall_area_after,
                           "m^3/s*m^2")
      runner.registerValue("infiltration_ach_after",
                           infiltration_ach_after,
                           "1/h")
    end
    if os_version >= min_version_feature2
      runner.registerFinalCondition("#{num_altered_infiltration_objects} space infiltration objects " + 
            "were altered affecting #{OpenStudio::toNeatString(affected_floor_area_ip,0)}(ft^2) " + 
            "of floor area at a total cost of $#{OpenStudio::toNeatString(final_cost,2)}. The " + 
            "requested infiltration reduction was #{space_infiltration_reduction_percent}%. Over " + 
            "the affected area, the new infiltration level is " + 
            "#{OpenStudio::toNeatStringBySigFigs(infiltration_ach_after,3)} ACH.")
    else
        runner.registerFinalCondition("#{num_altered_infiltration_objects} space infiltration objects " + 
            "were altered affecting #{affected_floor_area_ip}(ft^2) of floor area at " + 
            "a total cost of $#{final_cost}. The requested infiltration reduction was " + 
            "#{space_infiltration_reduction_percent}%")
    end

    return true

  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ReduceSpaceInfiltrationByPercentage.new.registerWithApplication
