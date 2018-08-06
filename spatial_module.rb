

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
      @function=SpatialType::GENERAL
    end

    def container()
      @container = Sketchup.active_model.entities.add_group() if @container == nil
      return @container
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


    def initialize(size,pos=Geom::Point3d.new(0,0,0),vect=nil, function=SpatialType::GENERAL, container)
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

      @size=size
      @base_pts=_make_base_points
      @additional_transformations=[]
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

      pts=[]
      pts<<@origin
      pts<<pts[0] + xvect
      pts<<pts[1] + yvect
      pts<<pts[0] + yvect
      return pts
    end
  end

  class BoxFlippable < Spatial::Box
    def initialize(size,pos=Geom::TracePoint.new(0,0,0),vect=nil, function=SpatialType::GENERAL, container)
      super(size,pos,vect,function, container)
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
    def self.linar(
            pos,
            sizes=[[3,3,3,3],10],
            arrangement=[
                SpatialType::F_STR,
                SpatialType::C_LIFTLOBBY,
                SpatialType::C_LIFT,
                SpatialType::F_STR
            ]
    )
      # function body
      count =sizes.size
      for i in 0..count

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

