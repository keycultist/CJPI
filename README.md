## CJPI (Canard JSON Parser/Importer) is a plugin developed in order to allow the userbase to create vignettes or graphics with their saved accessories, including their personalization.

Developed by 608b/Pleat for Type Moon and other associated games, namely, Canard.

This plugin is based off this following table, and is kept simple for the sole purpose of allowing others to learn from this system.
```lua
	local customizationData = {
		Height = character and character:GetScale() or 1,
		FaceID = "",
		ShirtID = shirt and shirt.ShirtTemplate or "",
		PantsID = pants and pants.PantsTemplate or "",
		Accessories = {},
		BodyColors = savedBodyColors or {},
		Name = nameLabel and nameLabel.Text or player.Name,
		Subtext = subtextLabel and subtextLabel.Text or "",
		Other = {}
	}
  ```
