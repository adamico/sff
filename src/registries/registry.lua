local Registry = {}

Registry.DeployableRegistry = require("src.registries.deployable_registry")
Registry.ItemRegistry = require("src.registries.item_registry")
Registry.EntityRegistry = require("src.registries.entity_registry")

return Registry
