// Import and register all your controllers from the importmap via controllers/**/*_controller
import { application } from "controllers/application"
import DropdownController from "controllers/dropdown_controller"
import LinenumbersEditorController from "controllers/linenumbers_editor_controller"
import InviteCodesController from "controllers/invite_codes_controller"
import ThemeController from "controllers/theme_controller"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
eagerLoadControllersFrom("controllers", application)

application.register("dropdown", DropdownController)
application.register("linenumbers-editor", LinenumbersEditorController)
application.register("invite-codes", InviteCodesController)
application.register("theme", ThemeController)
