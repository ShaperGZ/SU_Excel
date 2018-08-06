class BH_AptComponents < Arch::BlockUpdateBehaviour
  attr_accessor :components
  def initialize(gp,host)
    super(gp,host)
    @components=[]
  end

  def onChangeEntity(e, invalidated)
    super(e, invalidated)
    p "-> BH_AptComponents.onChangeEntity"
    # invalidate if invalidated[2]
    invalidate
  end

  def get_by_type(name)
    result=[]
    @components.each {|c|
      type_name = c.get_attribute("BuildingComponent","type")
      if type_name != nil
        if type_name==name
          result<<c
        end
      end
    }
    return result
  end

  def clear
    p "component size=#{@components.size}"
    return if @components.size<1
    for i in 0..@components.size-1
      comp=@components[i]
      if comp!=nil and comp.valid?
        comp.erase!
      end
    end
    @components=[]
  end

  def invalidate()
    clear
    yscale=@gp.transformation.yscale
    w,d,h=Op_Dimension.get_size(@gp)
    size=[w,d,h]
    p size
    for i in 0..size.size-1
      size[i]=size[i].m
    end

    p "size[1]=#{size[1]}"
    circulation_w=2.m
    pos=[]
    sizes=[]
    types=[]

    local_bounds=Op_Dimension.local_bound(@gp)

    if size[1]<=12.m
      rw=(size[1]-circulation_w)
      # rw/=yscale
      p "rw=#{rw.m}"
      pos<<local_bounds.min
      pos<<pos[0]+ Geom::Vector3d.new(0,rw/yscale,0)

      sizes<<[size[0],rw,size[2]]
      sizes<<[size[0],circulation_w,size[2]]

      types=["room","clt"]

    elsif size[1]<=25.m
      rw=(size[1]-circulation_w)/2
      # rw/=yscale

      pos<<local_bounds.min
      pos<<pos[0]+ Geom::Vector3d.new(0,rw/yscale,0)
      pos<<pos[0]+ Geom::Vector3d.new(0,(rw+circulation_w)/yscale,0)

      sizes<<[size[0],rw,size[2]]
      sizes<<[size[0],circulation_w,size[2]]
      sizes<<[size[0],rw,size[2]]

      types=["room","clt","room"]
    end

    return if pos.size==0
    zero=Geom::Point3d.new(0,0,0)

    for i in 0..pos.size-1
      offset=Geom::Transformation.translation(pos[i] - zero )
      comp=ArchUtil.add_box(zero,sizes[i],true,@gp,true)
      comp.transformation *= offset
      comp.set_attribute("BuildingComponent","type",types[i])
      @components<<comp
    end
  end
end


