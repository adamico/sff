local Registry = {}

Registry.AssemblerRegistry = require("src.registries.assembler_registry")
Registry.StorageRegistry = require("src.registries.storage_registry")
Registry.ItemRegistry = require("src.registries.item_registry")
Registry.EntityRegistry = require("src.registries.entity_registry")

return Registry
