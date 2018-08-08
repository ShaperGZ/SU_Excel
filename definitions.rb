# this class loads sketchup definitions to the system

class Definitions
  @@defs=Hash.new

  def self.defs
    return @@defs
  end

  def self.reload(path=nil)
    @@defs=Hash.new
    load(path)
  end

  def self.load(path=nil)
    path=SUExcel.get_file_path("/generator_components")
    files=Dir[path+"/*.skp"]
    files.each{|f|
      d=Sketchup.active_model.definitions.load(f)
      name=f.split('/')[-1]
      @@defs[name]=d
    }
  end
end