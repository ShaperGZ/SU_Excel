class BH_Apt_Circulation < Arch::BlockUpdateBehaviour
  def initialize(gp,host)
    super(gp,host)
    @core_geo=nil
  end

  def onChangeEntity(e, invalidated)
    p "-> BH_Apt_Circulation.onCHangeEntity"
    super(e, invalidated)
    # invalidate if invalidated[2]
    invalidate
  end



  def invalidate()
    bd_width=@host.attr("bd_width")
    bd_depth=@host.attr("bd_depth")

    components=@host.get_updator_by_type(BH_AptComponents)
    if components == nil
      p "please add BH_AptComponents to the building block prior to BH_Apt_Circulation"
      return
    end
    circulation=components.get_by_type("clt")

    if circulation == nil
      p " can not get a proper circulation from componetns"
    end
    circulation=circulation[0]
    clt_size=Op_Dimension.get_size(circulation)
    p "circulation.class = #{circulation.class}"

    yscale=@gp.transformation.yscale
    clt_y=circulation.transformation.origin.y.to_m * yscale
    p ("clt=#{clt_y} clt.to_s=#{circulation.to_s} clt.size=#{clt_size} clt.class=#{circulation.class}")
    clt_w=2.0
    core_y=clt_y+(clt_w/2.0)
    p "core_y=#{core_y}"

    cores=[]
    spaces=[]
    # 直线板式
    if bd_depth < 25


      if bd_width <= 42
        pos=[bd_width/2,core_y]
        size=[12,10]
        cores<<[pos,size]
        spaces<<Spatial::Box.new(size,pos,nil,SpatialType::F_STR,@gp)

      elsif bd_width <= 60
        pos1=[bd_width/3,core_y]
        size1=[3,8]
        # cores<<[pos1,size1]
        spaces<<Spatial::Box.new(size1,pos1,nil,SpatialType::F_STR,@gp)

        pos2=[(bd_width * 0.75)-3,core_y]
        size2=[9,10]
        # cores<<[pos2,size2]
        spaces<<Spatial::Box.new(size2,pos2,nil,SpatialType::F_STR,@gp)
      else bd_width <= 72
        pos1=[15,0]
        size1=[3,8]
        # cores<<[pos1,size1]
        spaces<<Spatial::Box.new(size1,pos1,nil,SpatialType::F_STR,@gp)

        pos2=[(bd_width-30)/2 + 30,core_y]
        size2=[12,10]
        spaces<<Spatial::Box.new(size2,pos2,nil,SpatialType::F_STR,@gp)
        # cores<<[pos2,size2]
      end


      # 单边客房
      if bd_depth<=15
        allow_external = @host.attr("p_bd_external_core")[0]
        if allow_external

        end


      # 双边客房
      else

      end


    end
    regen_spaces(spaces)
    # regen_cores(cores)
  end

  def clear()
    @core_geo.erase! if @core_geo!=nil and @core_geo.valid?
  end

  def regen_spaces(spaces)
    p '0 regen_spaces'
    return if spaces == nil or spaces.size<1
    clear()
    p '1 regen_spaces'
    height=@host.attr("bd_height") + 3
    height = height.m
    container=@gp.entities.add_group
    p "container= #{container}"
    spaces.each{|s|
      p "height#{height}"
      s.get_geometry(container,height,@gp)
    }

    @core_geo=container

  end

end