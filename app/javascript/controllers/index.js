// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import DropdownController from "controllers/dropdown_controller"
import LinenumbersViewerController from "controllers/linenumbers_viewer_controller"
import LinenumbersEditorController from "controllers/linenumbers_editor_controller"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

application.register("dropdown", DropdownController)
application.register("linenumbers-viewer", LinenumbersViewerController)
application.register("linenumbers-editor", LinenumbersEditorController)