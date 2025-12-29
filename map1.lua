return {
  version = "1.10",
  luaversion = "5.1",
  tiledversion = "1.11.2",
  class = "",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 30,
  height = 20,
  tilewidth = 32,
  tileheight = 32,
  nextlayerid = 5,
  nextobjectid = 1,
  properties = {},
  tilesets = {
    {
      name = "grass_path",
      firstgid = 1,
      class = "",
      tilewidth = 32,
      tileheight = 32,
      spacing = 0,
      margin = 0,
      columns = 8,
      image = "../../../Game Development/Itch.IO-Assets/Pixel Art Top Down - Basic v1.2.2/Texture/TX Tileset Grass.png",
      imagewidth = 256,
      imageheight = 256,
      objectalignment = "unspecified",
      tilerendersize = "tile",
      fillmode = "stretch",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 32,
        height = 32
      },
      properties = {},
      wangsets = {},
      tilecount = 64,
      tiles = {}
    },
    {
      name = "walls",
      firstgid = 65,
      class = "",
      tilewidth = 32,
      tileheight = 32,
      spacing = 0,
      margin = 0,
      columns = 16,
      image = "../../../Game Development/Itch.IO-Assets/Pixel Art Top Down - Basic v1.2.2/Texture/TX Tileset Wall.png",
      imagewidth = 512,
      imageheight = 512,
      objectalignment = "unspecified",
      tilerendersize = "tile",
      fillmode = "stretch",
      tileoffset = {
        x = 0,
        y = 0
      },
      grid = {
        orientation = "orthogonal",
        width = 32,
        height = 32
      },
      properties = {},
      wangsets = {},
      tilecount = 256,
      tiles = {}
    }
  },
  layers = {
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 30,
      height = 20,
      id = 1,
      name = "Floors",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      encoding = "lua",
      chunks = {
        {
          x = 0, y = 0, width = 16, height = 16,
          data = {
            1, 2, 3, 4, 1, 2, 33, 34, 33, 2, 3, 4, 1, 2, 3, 4,
            9, 10, 11, 12, 9, 10, 41, 42, 41, 10, 11, 12, 9, 10, 11, 12,
            17, 18, 19, 20, 17, 18, 49, 50, 49, 18, 19, 20, 17, 18, 19, 20,
            25, 26, 27, 28, 25, 26, 33, 34, 33, 26, 27, 28, 25, 26, 27, 28,
            1, 2, 3, 4, 1, 2, 41, 42, 41, 2, 3, 4, 1, 2, 3, 4,
            9, 10, 11, 12, 9, 10, 49, 50, 49, 10, 11, 12, 9, 10, 11, 12,
            33, 34, 33, 34, 33, 34, 33, 34, 33, 33, 34, 33, 34, 33, 34, 33,
            41, 42, 41, 42, 41, 42, 41, 42, 41, 41, 42, 41, 42, 41, 42, 41,
            33, 34, 33, 34, 33, 34, 49, 50, 49, 33, 34, 33, 34, 33, 34, 33,
            9, 10, 11, 12, 9, 10, 33, 34, 33, 0, 0, 0, 0, 0, 0, 0,
            17, 18, 19, 20, 17, 18, 41, 42, 41, 0, 0, 0, 0, 0, 0, 0,
            25, 26, 27, 28, 25, 26, 49, 50, 49, 0, 0, 0, 0, 0, 0, 0,
            1, 2, 3, 4, 1, 2, 33, 34, 33, 0, 0, 0, 0, 0, 0, 0,
            9, 10, 11, 12, 9, 10, 41, 42, 41, 0, 0, 0, 0, 0, 0, 0,
            17, 18, 19, 20, 17, 18, 49, 50, 49, 0, 0, 0, 0, 0, 0, 0,
            25, 26, 27, 28, 25, 26, 33, 34, 33, 26, 0, 0, 0, 0, 0, 0
          }
        }
      }
    },
    {
      type = "tilelayer",
      x = 0,
      y = 0,
      width = 30,
      height = 20,
      id = 2,
      name = "Walls",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {
        ["solid"] = true
      },
      encoding = "lua",
      chunks = {
        {
          x = 0, y = 0, width = 16, height = 16,
          data = {
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 82, 83, 83, 0, 83, 83, 84,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 98, 0, 0, 0, 0, 0, 100,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 98, 0, 0, 0, 0, 0, 100,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 98, 0, 0, 0, 0, 0, 100,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 98, 0, 0, 0, 0, 0, 100,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 125, 115, 167, 87, 167, 165, 116,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 141, 131, 183, 131, 183, 131, 132
          }
        }
      }
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 3,
      name = "Entities",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {}
    },
    {
      type = "objectgroup",
      draworder = "topdown",
      id = 4,
      name = "Triggers",
      class = "",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      parallaxx = 1,
      parallaxy = 1,
      properties = {},
      objects = {}
    }
  }
}
