# this class loads sketchup definitions to the system


class Definitions
  @@loaded=false
  @@defs=Hash.new

  def self.loaded
    return @@loaded
  end

  def self.defs
    return @@defs
  end

  def self.reload(path=nil)
    @@defs=Hash.new
    load(path,true)
    @@loaded=true
  end

  def self.load(path=nil, forced=false)
    return if @@loaded and not forced
    path=SUExcel.get_file_path("/generator_components") if path==nil
    files=Dir[path+"/*.skp"]
    files.each{|f|
      d=Sketchup.active_model.definitions.load(f)
      next if d.class != Sketchup::ComponentDefinition
      name=f.split('/')[-1]
      @@defs[name]=d
    }
    p "[#{@@defs.size} definitions loaded successfully]"
    @@loaded=true
  end

  # instantiate a definition
  def self.instantiate(conatiner,key,transformation)
    d=@@defs[key]
    #p "@@defs=#{@@defs} defs.size=#{@@defs.size} d=#{d} key=#{key}"
    o=conatiner.entities.add_instance(d,Geom::Transformation.new)
    o.transformation=transformation
    return o
  end

end