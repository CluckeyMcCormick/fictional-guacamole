from . import (
	terrain_detail,
	terrain_primary
)

# Ensure that the detail Enums know their image path
terrain_detail.PrototypeEdgeKey.image_path = terrain_detail.IMAGE_PATH
terrain_detail.EdgeKey.image_path = terrain_detail.IMAGE_PATH
terrain_detail.DetailKey.image_path = terrain_detail.IMAGE_PATH

# Ensure that the primary Enums knows it's image path
terrain_primary.PrimaryKey.image_path = terrain_primary.IMAGE_PATH

