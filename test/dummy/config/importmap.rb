# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"

# Pin FlatPack controllers from the engine
pin_all_from File.expand_path("../../../app/javascript/flat_pack/controllers", __dir__), under: "controllers/flat_pack", to: "flat_pack/controllers", preload: false
pin_all_from File.expand_path("../../../app/javascript/flat_pack/tiptap", __dir__), under: "flat_pack/tiptap", to: "flat_pack/tiptap", preload: false
pin "flat_pack/heroicons", to: "flat_pack/heroicons.js", preload: false
