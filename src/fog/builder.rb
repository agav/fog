module Fog

  # Everything that reads or changes the SketchUp model for button 1
  module Builder

    # Shape result of a group
    def self.analyze(group)
      return Shape::Result.new('The group is locked.') if group.locked?
      entities = group.definition.entities
      unless entities.all? { |e| e.is_a?(Sketchup::Face) || e.is_a?(Sketchup::Edge) }
        return Shape::Result.new('It must contain only faces and edges.')
      end
      t = group.transformation
      mm = ->(vertex) { vertex.position.transform(t).to_a.map(&:to_mm) }
      faces = entities.grep(Sketchup::Face).map do |face|
        { outer: face.outer_loop.vertices.map(&mm),
          inners: face.loops.reject(&:outer?).map { |l| l.vertices.map(&mm) } }
      end
      Shape.analyze(faces, entities.grep(Sketchup::Edge).flat_map(&:vertices).uniq.map(&mm))
    end

    # Direction from the center of the points to the camera, in model space
    def self.to_camera(view, points)
      camera = view.camera
      return camera.direction.reverse.to_a unless camera.perspective?
      center = points.transpose.map { |c| c.sum / c.length }
      Vec.sub(camera.eye.to_a.map(&:to_mm), center)
    end

    # All names that a new unit must not be in conflict with
    def self.existing_names(model)
      definitions = model.definitions.reject { |d| d.group? || d.image? }
      model.layers.to_a.map(&:name) + _folders(model.layers).map(&:name) + definitions.map(&:name) +
        model.pages.map(&:name)
    end

    # Replaces the group with the body. One undo operation.
    def self.build(model, group, name, panels)
      model.start_operation('FOG Body', true)
      begin
        tag = model.layers.add("#{name}-body")
        folder = model.layers.add_folder(name)
        folder.add_layer(tag)
        initial_tag = group.layer
        material = _material(group)

        body = model.entities.add_group
        body.name = "#{name}-body"
        body.layer = tag
        panels.each do |panel|
          instance = body.entities.add_instance(_definition(model, "#{name}-body-#{panel.role}", panel),
                                                _transformation(panel))
          instance.layer = initial_tag
          instance.material = material
        end
        group.erase!

        _make_scene(model, name, folder, tag, initial_tag)
        model.commit_operation
      rescue StandardError
        model.abort_operation
        raise
      end
    end

    def self._folders(parent)
      parent.folders.flat_map { |f| [ f ] + _folders(f) }
    end

    # The material of the group, else the material that all its faces have
    def self._material(group)
      return group.material if group.material
      materials = group.definition.entities.grep(Sketchup::Face).map(&:material).uniq
      materials.length == 1 ? materials.first : nil
    end

    # A box in the positive octant of the definition axes, with no material and no tag
    def self._definition(model, name, panel)
      definition = model.definitions.add(name)
      l, w, t = panel.size
      face = definition.entities.add_face([ 0, 0, 0 ], [ l.mm, 0, 0 ], [ l.mm, w.mm, 0 ], [ 0, w.mm, 0 ])
      face.reverse! if face.normal.z < 0
      face.pushpull(t.mm)
      definition
    end

    def self._transformation(panel)
      Geom::Transformation.axes(Geom::Point3d.new(*panel.origin.map(&:mm)), Geom::Vector3d.new(*panel.red),
                                Geom::Vector3d.new(*panel.green), Geom::Vector3d.new(*panel.blue))
    end

    # The new scene saves the current state of the model, so the tags are set in the model first.
    # Thus the scene is also the active view. Untagged stays visible: the panel geometry is on it.
    def self._make_scene(model, name, folder, tag, initial_tag)
      layers = model.layers
      visible = [ tag, initial_tag, layers[0] ]
      model.active_layer = layers[0] unless visible.include?(model.active_layer)
      layers.each { |layer| layer.visible = visible.include?(layer) }
      _folders(layers).each { |f| f.visible = f == folder || _contains?(f, initial_tag) }
      model.pages.selected_page = model.pages.add(name)
    end

    def self._contains?(folder, layer)
      folder.layers.include?(layer) || folder.folders.any? { |f| _contains?(f, layer) }
    end

  end

end
