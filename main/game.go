components {
  id: "script"
  component: "/main/game.script"
}
embedded_components {
  id: "background"
  type: "sprite"
  data: "default_animation: \"table\"\n"
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
  position {
    z: -0.9
  }
}
embedded_components {
  id: "score_factory"
  type: "factory"
  data: "prototype: \"/main/hud_score.go\"\n"
  ""
}
embedded_components {
  id: "time_factory"
  type: "factory"
  data: "prototype: \"/main/hud_time.go\"\n"
  ""
}
embedded_components {
  id: "best_factory"
  type: "factory"
  data: "prototype: \"/main/hud_best.go\"\n"
  ""
}
embedded_components {
  id: "hint_factory"
  type: "factory"
  data: "prototype: \"/main/hud_hint.go\"\n"
  ""
}
embedded_components {
  id: "card_factory"
  type: "factory"
  data: "prototype: \"/main/card.go\"\n"
  ""
}
embedded_components {
  id: "pop_factory"
  type: "factory"
  data: "prototype: \"/main/pop.go\"\n"
  ""
}
embedded_components {
  id: "ring_factory"
  type: "factory"
  data: "prototype: \"/main/hint_ring.go\"\n"
  ""
}
embedded_components {
  id: "snd_tap"
  type: "sound"
  data: "sound: \"/assets/sfx/snd_tap.wav\"\n"
  ""
}
embedded_components {
  id: "snd_bounce"
  type: "sound"
  data: "sound: \"/assets/sfx/snd_bounce.wav\"\n"
  ""
}
embedded_components {
  id: "snd_finish"
  type: "sound"
  data: "sound: \"/assets/sfx/snd_finish.wav\"\n"
  ""
}
embedded_components {
  id: "music"
  type: "sound"
  data: "sound: \"/assets/music/theme.wav\"\n"
  "looping: 1\n"
  ""
}
