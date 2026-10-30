components {
  id: "script"
  component: "/main/pop.script"
}
embedded_components {
  id: "sprite"
  type: "sprite"
  data: "default_animation: \"glow\"\n"
  "material: \"/builtins/materials/sprite.material\"\n"
  "size {\n"
  "  x: 1.0\n"
  "  y: 1.0\n"
  "}\n"
  "size_mode: SIZE_MODE_MANUAL\n"
  "textures {\n"
  "  sampler: \"texture_sampler\"\n"
  "  texture: \"/main/uncompressed/fx.atlas\"\n"
  "}\n"
  ""
}
