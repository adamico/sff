return {
   name = "Dungeon Theme",
   components = {
      framev1 = {
         atlas = "themes/dungeon/frame/frame1.9.png",
      },
      buttonv1 = {
         atlas = "themes/dungeon/button/button1.9.png",
         states = {
            hover = {
               atlas = "themes/dungeon/button/button2.9.png",
            },
            pressed = {
               atlas = "themes/dungeon/button/button2.9.png",
            },
            disabled = {
               atlas = "themes/dungeon/button/button3.9.png",
            },
         },
      },
   },

   -- Optional: Theme fonts
   -- Define font families that can be referenced by name
   -- Paths are relative to FlexLove location or absolute
   fonts = {
      default = "themes/dungeon/font/TinyFontCraftpixPixel.otf",
   },
}
