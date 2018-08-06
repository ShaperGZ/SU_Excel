

module Spatial
  class SpatialModule
    attr_accessor :base_pts
    attr_accessor :origin
    attr_accessor :function

    def initialize(pos = Geom::Point3d.new(0,0,0), vect=nil, function=SpatialType::GENERAL, container=nil)
      @base_pts = []
      @origin = pos
      @vect=nil
      @container = container
      @function=function
    end

    def container()
      @container = Sketchup.active_model.entities.add_group() if @container == nil
      return @container
    end

    def get_org_size()
      org=@base_pts[0]
      w=(@base_pts[1]-@base_pts[0]).length
      d=(@base_pts[3]-@base_pts[0]).length
      size=[w.to_m,d.to_m]
      return org,size
    end

    def get_geometry(container,h=0,unscale_ref=nil)


      if unscale_ref != nil
        xscale=unscale_ref.transformation.xscale
        yscale=unscale_ref.transformation.yscale
        zscale=unscale_ref.transformation.zscale

        t=ArchUtil.Transformation_scale_3d([1.0 / xscale, 1.0 / yscale, 1.0 / zscale])
        base_pts=_make_base_points
        tbase_pts=[]
        base_pts.each{|p|
          tbase_pts<<t * p
        }
      else
        xscale=yscale=zscale=1
        tbase_pts=[]
        base_pts.each{|p|
          tbase_pts<<p.clone
        }
      end

      f = container.entities.add_face(tbase_pts)
      f.reverse! if f.normal.z<0
      if h != 0
        f.pushpull( (h/zscale) )
      end
      return container
    end

    def set_vect(vect)
      @vect = vect
      _make_base_points
    end

    def get_vect()
      return @vect if @vect!= nil and @vect.class = Geom::Vector3d
      return Geom::Vector3d.new(1,0,0)
    end

    def set_pos(pos)
      @origin = pos
      _make_base_points
    end

    def _make_base_points
      # override
    end
  end

  class Box < Spatial::SpatialModule
    attr_accessor :size


    def initialize(size,
                   pos=Geom::Point3d.new(0,0,0),
                   vect=nil,
                   function=SpatialType::GENERAL,
                   container=nil,
                   alignment=Alignment::SW)
      if pos.class == Array
        x=pos[0].m
        y=pos[1].m
        if pos.size==3
          z= pos[2].m
        else
          z=0
        end
        pos=Geom::Point3d.new(x,y,z)
      end

      for i in 0..size.size-1
        size[i]=size[i].m
      end

      super(pos,vect,function,container)

      @alignment = alignment
      @size=size
      @base_pts=_make_base_points
      @additional_transformations=[]
    end

    def alignment()
      return @alignment
    end

    def alignment=(val)
      @alignment = val
      _make_base_points
    end

    def _make_base_points()
      if @vect == nil
        xvect = Geom::Vector3d.new(1,0,0)
        yvect = Geom::Vector3d.new(0,1,0)
      else
        xvect = @vect.normalize
        yvect = Geom::Vector3d.new(0,0,1).cross(xvect)
      end

      xvect.length=@size[0]
      yvect.length=@size[1]

      halfx=xvect.clone
      halfx.length=xvect.length/2
      halfy=yvect.clone
      halfy.length=halfy.length/2

      org = @origin
      case(alignment)
      when Alignment::SW
        org = @origin
      when Alignment::SE
        org = @orgin - xvect
      when Alignment::NW
        org = @origin - yvect
      when Alignment::NE
        org = @origin - xvect - yvect
      when Alignment::S
        org = @origin - halfx
      when Alignment::N
        org = @origin - halfx - yvect
      when Alignment::W
        org = @origin - halfy
      when Alignment::E
        org = @origin - halfx - xvect
      else
        org = @origin - halfx - halfy
      end

      pts=[]
      pts<<org
      pts<<pts[0] + xvect
      pts<<pts[1] + yvect
      pts<<pts[0] + yvect
      return pts
    end
  end

  class BoxFlippable < Spatial::Box
    def initialize(size,
                   pos=Geom::TracePoint.new(0,0,0),
                   vect=nil,
                   function=SpatialType::GENERAL,
                   container=nil,
                   alignment=Alignment::SW)
      super(size,pos,vect,function, container, alignment)
    end

    def _make_base_points()
      super()
      @additional_transformations.each{|t|
        @container.transformation *= t
      }
    end
    def flip(side="left")
      offset_vect=Geom::Vector3d(0,0,1).cross(get_vect)
      offset_vect.length=@size[0]/2

      if side=="left"
        angle=90.degrees
      elsif side == "right"
        angle=-90.degrees
      end

      @additional_transformations=[]
      @additional_transformations<< Geom::Transformation.translate(offset_vect)
      @additional_transformations<< Geom::Transformation.rotattion(@origin, Geom::Vector3d.new(0,0,1), 90.degrees)
    end
  end

  def Spatial.interpret_core_flbf(space,container=nil,h=0,unscale_ref=nil)
    # size resulted in m
    org, size = space.get_org_size()
    p "interpret org=#{org}, sie=#{size}"

    if unscale_ref!=nil
      xscale=unscale_ref.transformation.xscale
      yscale=unscale_ref.transformation.yscale
      zscale=unscale_ref.transformation.zscale
    else
      xscale=yscale=zscale=1
    end

    xvect=Geom::Vector3d.new(1,0,0)
    spaces=[]
    sizes=[]
    poses=[]
    types=[]
    if size[0] >= 12 and size[0] < 15
      flex=size[0]-9
      sizes=[3,flex,3,3]
      vs=[]
      for i in 1..sizes.size-1
        ivs=xvect.clone
        ivs.length = sizes[i-1].m / xscale
        vs<<ivs
      end
      poses=[
          org.clone,
          org+vs[0],
          org+vs[1],
          org+vs[2]
      ]
      types=[
          SpatialType::F_STR,
          SpatialType::C_LIFTLOBBY,
          SpatialType::C_LIFT,
          SpatialType::F_STR
      ]

    elsif size[0] < 12 and size[0] >= 9

      flex=size[0]-6
      sizes=[flex,3,3]
      vs=[]
      for i in 1..sizes.size-1
        ivs=xvect.clone
        ivs.length = sizes[i-1].m / xscale
        vs<<ivs
      end
      poses=[
          org.clone,
          org+vs[0],
          org+vs[1]
      ]
      types=[
          SpatialType::C_LIFTLOBBY,
          SpatialType::C_LIFT,
          SpatialType::F_STR,
      ]
    end

    for i in 0..sizes.size-1
      s=sizes[i]
      p=poses[i]
      t=types[i]

      s=Spatial::Box.new([s,size[1]],p,nil,t,unscale_ref,Alignment::SW)
      spaces<<s
    end

    p "spaces.size=#{spaces.size}"
    geo=[]
    spaces.each {|s|
      g=s.get_geometry(container,h,unscale_ref)
      geo<<g
    }
    return geo
  end


  # use letter abbreviation to generate types
  # the array contains columns, each column containers row items
  # i.e. [
  #        [item1, item2],
  #        [],
  #        []
  #      ]
  #
  # item:[typestr,size]
  class Compositions
    def initialzie()
      @sub_sizes=[]
      @sub_poses=[]

    end
    def self.linar(
            pos,
            sizes=[[3,3,3,3],10],
            arrangement=[
                SpatialType::F_STR,
                SpatialType::C_LIFTLOBBY,
                SpatialType::C_LIFT,
                SpatialType::F_STR
            ],
            alignment=Alignment.S
    )
      # function body
      xvect=Geom::Vector3d(1,0,0)
      total_w=0
      sizes[0].each{|n| total_w+=n}

      case (alignment)
      when Alignment.S
        offset=Geom::Vector3d.new(-total_w/2,0,0)
      when Alignment.SW
        offset=nil
      when Alignment.SE
        offset = Geom::Vector3d.new(-total_w,0,0)
      end



      sub_sizes=[]
      sub_poses=[]
      count =sizes[0].size
      accumulated=0
      for i in 0..count
        sub_sizes<<[sizes[0][i],sizes[1]]
        ipos=pos
        ipos += offset if offset!=nil
        if i > 0
          xvect.length=(sizes[0][i-1]).m + accumulated
          sub_poses<<ipos + xvect
        else
          sub_poses<<ipos
        end

        accumulated+=sizes[0][i].m
      end

    end

    #
    # def self.grid(pos, arrangement=[
    #     [],
    #     [],
    #     []
    # ])
    #   currpos=Geom::Point3d.new(0,0,0)
    #   creation=[]
    #   arrangement.each{|column|
    #     column.each{|i|
    #       space=Box.new(i[1],function=i[0])
    #       creation<<space
    #     }
    #
    #   }
    #
    # end
  end
end

