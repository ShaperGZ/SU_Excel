load 'archi.rb'
load 'arch_util.rb'
au=ArchUtil

$TEXTURE_PATH='c:/SketchupRuby/grid/'

module Arch
  class ShadowBlock < Arch::Block
    def initialize(gp,shadowsCount=3)
      super(gp)
      @trash=[]
      @shadows=[]
      @shadowCount=shadowsCount
      @shadowOffset=300
    end

    def updateShadowContent()
      eraseAllShadows()
      for i in 0..@shadowCount
        j=i+1
        shadow=@gp.copy
        vector = Geom::Vector3d.new(0, j*@shadowOffset, 0)
        tr = Geom::Transformation.translation(vector)
        shadow.transform! tr
        @shadows<<shadow
      end

    end

    def eraseAllShadows()
      for i in 0..@shadows.size
        @shadows[i].erase! if @shadows[i] != nil and @shadows[i].deleted? == false
      end
      @shadows=[]
    end



    def showAllShadow(b)
      for i in 0..@shadows.size
        if b
          @shadows[i].hidden = false if @shadows[i]!=nil and @shadows[i].deleted? == false
        else
          @shadows[i].hidden = true if @shadows[i]!=nil and @shadows[i].deleted? == false
        end
      end
    end

    def onElementModified(entities, e)
      @enableUpdate=false
      #p "shodowBlock.onElementModified: #{e} enableUpdate=#{enableUpdate()}"
      updateShadowContent()
      @enableUpdate=true
    end

    def onOpen(e)
      showAllShadow(true)
    end
    def onClose(e)
      showAllShadow(false)

    end
  end

  class ExpBlock < ShadowBlock
    def initialize(gp,shadowsCount=3)
      super(gp)
      @shadows=[]
      @shadowCount=shadowsCount
      @shadowOffset=300
      @flrs=nil
      updateShadowContent()
      onClose(nil)
    end
    def updateShadowContent()
      super
      @flrs.erase! if @flrs!=nil
      e=@shadows[0].copy if @shadows.size>1 and @shadows[0]!=nil and @shadows[0].deleted? == false
      o=ArchUtil.genFlrs(e,3,1)
      @flrs=o[0]
      e.erase!
    end
    def onEraseEntity(e)
      eraseAllShadows()
      @flrs.erase! if @flrs!=nil
    end
    def onOpen(e)
      super
      offset=@shadowOffset
      ArchUtil.translate(@flrs,0,offset / $m2inch, 0)
    end
    def onClose(e)
      super
      offset=@shadowOffset
      ArchUtil.translate(@flrs,0,-offset / $m2inch, 0)
    end
  end

  class AptBlock < Arch::Block
    def initialize(gp,bay=4.5,ftfh=4.5)
      @ftfh=ftfh
      @bayWidth=bay
      @m_wall=ArchUtil.setTextureMaterial('gridAptWall',$TEXTURE_PATH+'grid2.jpg',1.5,4.5)
      @m_top=ArchUtil.setTextureMaterial('gridAptTop',$TEXTURE_PATH+'grid2.jpg',3,3)
      setFTFH(ftfh)
      setBayWidth(bay)

      pos=gp.transformation.origin
      ngp=ArchUtil.makeBox(pos,30,20,30)
      gp.erase!
      _apply_material(ngp)
      super(ngp)
    end

    def _apply_material(gp)
      ents=gp.entities
      pt_array = []
      pt_array[0] = Geom::Point3d.new(0,0,0)
      pt_array[1] = Geom::Point3d.new(0,0,0)
      for i in 0..ents.size-1
        e=ents[i]
        if e.class == Sketchup::Face
          if e.normal.z.abs==1
            e.position_material(@m_top, pt_array, true)
          else
            e.position_material(@m_wall, pt_array, true)
          end
        end
      end
    end

    def setFTFH(h=3)
      @m_wall=ArchUtil.setTextureMaterial('gridAptWall',$TEXTURE_PATH+'grid2.jpg',1.5,h)
      @ftfh=h
    end
    def setBayWidth(w=4.5)
      @bayWidth=w
      dv=(w/1.5).round
      @facadeW= w / dv
      #p "facadeW=#{@facadeW} dv=#{dv}"
      @m_wall=ArchUtil.setTextureMaterial('gridAptWall',$TEXTURE_PATH+'grid2.jpg',@facadeW,@ftfh)
      @m_top=ArchUtil.setTextureMaterial('gridAptTop',$TEXTURE_PATH+'grid2.jpg',w,w)
    end
    def onOpen(e)

    end

    def onClose(e)

    end

    def onChangeEntity(e)

    end

    def onEraseEntity(e)

    end

    def onElementAdded(entities, e)
      #p "added #{e}"
    end

    def onElementModified(entities, e)
      @enableUpdate=false
      p "modify #{e}"
      if e.class == Sketchup::Face
        if e.normal.z==1
          p "constrain top"
          ArchUtil.constrainFace(e,@ftfh)
        else
          p "constrain wall"
          ArchUtil.constrainFace(e,@facadeW)
        end
      end
      _apply_material(@gp)
      @enableUpdate=true
    end
  end
end


