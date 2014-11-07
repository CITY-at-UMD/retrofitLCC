class ExteriorWallInsulationandFinishSystem < OpenStudio::Ruleset::ModelUserScript
  
  #define the name that a user will see, this method may be deprecated as
  #the display name in PAT comes from the name field in measure.xml
  def name
    return "ExteriorWallInsulationandFinishSystem"
  end
  
  #define the arguments that the user will input
  def arguments(model)
    args = OpenStudio::Ruleset::OSArgumentVector.new
    
    #make an argument for insulation thickness
    insul_tchkn = OpenStudio::Ruleset::OSArgument::makeDoubleArgument("insul_tchkn",true)
    insul_tchkn.setDisplayName("Insulation Thickness (in):")
	insul_tchkn.setDefaultValue(4)
    args << insul_tchkn 
	
    return args
  end #end the arguments method

  #define what happens when the measure is run
  def run(model, runner, user_arguments)
    super(model, runner, user_arguments)
    
    #use the built-in error checking 
    if not runner.validateUserArguments(arguments(model), user_arguments)
      return false
    end

    #assign the user inputs to variables
    insul_tchkn = runner.getDoubleArgumentValue("insul_tchkn",user_arguments)
    #add_space = runner.getBoolArgumentValue("add_space",user_arguments)

    #check if insul_tchkn present
    if insul_tchkn == ""
      runner.registerError("No Insulation Thickness Was Entered")
      return false
    end 
	
	#ruby test to see if insul_tchkn is reasonable
    if insul_tchkn < 0 or insul_tchkn > 12 
      runner.registerWarning("Insulation thickness must be between 0 and 12 (in). You entered #{insul_tchkn}")    
    end
    
	# make a new material layer
	options = {
		"layerIndex" => 0, # 0 will be outside. Measure writer should validate any non 0 layerIndex passed in.
		"name" => "Exterior Wall and Finish System",
		"roughness" => "MediumRough",
		"thickness" => insul_tchkn*0.0254, # meters,
		"conductivity" => 0.0360563953045152, # W/m*K
		"density" => 25.6295413983362,
		"specificHeat" => 1465.38,
		"thermalAbsorptance" => 0.9,
		"solarAbsorptance" => 0.7,
		"visibleAbsorptance" => 0.7,
	}
	exposedMaterialNew = OpenStudio::Model::StandardOpaqueMaterial.new(model)
	exposedMaterialNew.setName(options["name"])	
	# set requested material properties
	if not options["roughness"].nil? then exposedMaterialNew.setRoughness(options["roughness"]) end
	if not options["thickness"].nil? then exposedMaterialNew.setThickness(options["thickness"]) end
	if not options["conductivity"].nil? then exposedMaterialNew.setConductivity( options["conductivity"]) end
	if not options["density"].nil? then exposedMaterialNew.setDensity(options["density"])end
	if not options["specificHeat"].nil? then exposedMaterialNew.setSpecificHeat(options["specificHeat"]) end
	if not options["thermalAbsorptance"].nil? then exposedMaterialNew.setThermalAbsorptance(options["thermalAbsorptance"]) end
	if not options["solarAbsorptance"].nil? then exposedMaterialNew.setSolarAbsorptance(options["solarAbsorptance"]) end
	if not options["visibleAbsorptance"].nil? then exposedMaterialNew.setVisibleAbsorptance(options["visibleAbsorptance"]) end
	
	#create an array of exterior walls
    surfaces = model.getSurfaces
    exterior_surfaces = []
    exterior_surface_constructions = []
    exterior_surface_construction_names = []
	exterior_surfaces_num_layers = []
	
    surfaces.each do |surface|	
      if not surface.construction.empty?      	  
        if surface.outsideBoundaryCondition == "Outdoors" and surface.surfaceType == "Wall"
			exterior_surfaces << surface
			ext_wall_const = surface.construction.get
			#only add construction if it hasn't been added yet
			if not exterior_surface_construction_names.include?(ext_wall_const.name.to_s)
			  exterior_surface_constructions << ext_wall_const.to_Construction.get
			end
			exterior_surface_construction_names << ext_wall_const.name.to_s 
		end #end of surface.outsideBoundaryCondition	  
	  end # end of if not surface.construction.empty?	  
    end # end of surfaces.each do
	
	    # nothing will be done if there are no exterior surfaces
    if exterior_surfaces.empty?
      runner.registerAsNotApplicable("Model does not have any exterior walls.")
      return true
    end	

	# for each exterior surface construction, add the new material layer to the construction
	num_constructions_changed = 0
	exterior_surface_constructions.each do |exterior_surface_construction|
	  # add new material layer to construction 
	  exterior_surface_construction.insertLayer(options["layerIndex"],exposedMaterialNew)	
	  runner.registerInfo("Added #{exposedMaterialNew.name.to_s} to construction #{exterior_surface_construction.name.to_s}.")
	  num_constructions_changed += 1
	end
		
	#returning the insulation thickness
    runner.registerInfo("Applied Insulation of Thickness #{insul_tchkn}(in) to #{num_constructions_changed} Building Constructions.")
	
    return true
 
  end #end the run method

end #end the measure

#this allows the measure to be use by the application
ExteriorWallInsulationandFinishSystem.new.registerWithApplication