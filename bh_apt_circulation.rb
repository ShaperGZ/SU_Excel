class BH_Apt_Circulation < Arch::BlockUpdateBehaviour
  def initialize(gp,host)
    super(gp,host)
    @core_geo=nil
  end

  def onChangeEntity(e, invalidated)
    super(e, invalidated)
    invalidate if invalidated[2]
  end



  def invalidate()

    bd_width=@host.attr("bd_width")
    bd_depth=@host.attr("bd_depth")

    cores=[]
    # 直线板式
    if bd_depth < 25
      if bd_width <= 42
        pos=[bd_width/2,0]
        size=[12,10]
        cores<<[pos,size]
      elsif bd_width <= 60
        pos1=[bd_width/3,0]
        size1=[3,8]
        cores<<[pos1,size1]

        pos2=[(bd_width * 0.75)-3,0]
        size2=[9,10]
        cores<<[pos2,size2]
      else bd_width <= 72
        pos1=[15,0]
        size1=[3,8]
        cores<<[pos1,size1]

        pos2=[(bd_width-30)/2 + 30,0]
        size2=[12,10]
        cores<<[pos2,size2]
      end


      # 单边客房
      if bd_depth<=15

      # 双边客房
      else

      end


    end
    regen_cores(cores)
  end

  def clear()
    @core_geo.erase! if @core_geo!=nil and @core_geo.valid?
  end

  def regen_cores(cores)
    clear()
    return if cores == nil or cores.size<1

    height=@host.attr("bd_height") + 3
    height/=@gp.transformation.zscale
    container=Sketchup.active_model.entities.add_group
    xscale=@gp.transformation.xscale
    yscale=@gp.transformation.yscale

    cores.each{|c|
      p "c=#{c} xscale=#{xscale} yscale=#{yscale}"
      pos=c[0]
      size=c[1]
      #center
      pos[0]-=(size[0]/2)

      #scale
      pos[0]/=xscale
      pos[1]/=yscale
      size[0]/=xscale
      size[1]/=yscale

      base_pts=[]
      base_pts<<Geom::Point3d.new(pos[0].m, pos[1].m)
      base_pts<<base_pts[0] + Geom::Vector3d.new(size[0].m,0,0)
      base_pts<<base_pts[1] + Geom::Vector3d.new(0,size[1].m,0)
      base_pts<<base_pts[0] + Geom::Vector3d.new(0,size[1].m,0)

      f=container.entities.add_face(base_pts)
      f.reverse! if f.normal.z<0
      f.pushpull(height.m)
    }

    container.transformation=@gp.transformation
    @core_geo=container
    return container
  end

end