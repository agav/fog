require 'sketchup.rb'
require 'extensions.rb'

module Fog

  unless file_loaded?(__FILE__)
    ex = SketchupExtension.new('FOG', File.join(File.dirname(__FILE__), 'fog', 'main'))
    ex.version     = '0.1.0'
    ex.creator     = 'Oleksandr Gavrylenko'
    ex.copyright   = 'Oleksandr Gavrylenko'
    ex.description = 'Furniture Oleksandr Gavrylenko: changes a drawn shape into a furniture unit with panels, tags and a scene.'
    Sketchup.register_extension(ex, true)
    file_loaded(__FILE__)
  end

end
