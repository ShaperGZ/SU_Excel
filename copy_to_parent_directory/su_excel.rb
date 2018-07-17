require 'sketchup.rb'
require 'extensions.rb'
require 'langhandler.rb'

module Sketchup::Excel

$tStrings = LanguageHandler.new("server.strings")

#Register the Sandbox Tools with SU's extension manager
meshToolsExtension = SketchupExtension.new($tStrings.GetString(
  "Excel通信工具"), "su_excel/entry.rb")

meshToolsExtension.description=$tStrings.GetString(
  "Adds items to the Draw and Tools menus for creating and editing " +
  "organic shapes such as terrain.")
meshToolsExtension.version = "2.2.4"
meshToolsExtension.creator = "SketchUp"
meshToolsExtension.copyright = "2014, Trimble Navigation Limited"

#Default on in pro and off in free
Sketchup.register_extension meshToolsExtension, Sketchup.is_pro?


end # module Sketchup::SandboxTools
