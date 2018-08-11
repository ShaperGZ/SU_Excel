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
    load(path)
    @@loaded=true
  end

  def self.load(path=nil)
    p "1 loading def"
    return if @@loaded
    p "2 loading def"
    path=SUExcel.get_file_path("/generator_components") if path==nil
    files=Dir[path+"/*.skp"]
    files.each{|f|
      d=Sketchup.active_model.definitions.load(f)
      name=f.split('/')[-1]
      @@defs[name]=d
    }
    @@loaded=true
  end

end