# FOG

FOG (Furniture Oleksandr Gavrylenko) is a SketchUp extension. It changes a simple drawn shape into a furniture unit with the correct panels, tags and scene.
It is a companion of [ocl-joints](https://github.com/agav/ocl-joints) and [ocl-viyar](https://github.com/agav/ocl-viyar).

The requirements are in [docs/requirements.md](docs/requirements.md).

Status: only the **Body** button works. The buttons **Fronts**, **Back**, **Edge bindings** and **Joints** are placeholders.

## Install

1. Run `python3 tools/build_rbz.py`. The file `dist/fog_<version>.rbz` is made.
2. In SketchUp, open **Extensions > Extension Manager > Install Extension**. Select the `.rbz` file.

For development, copy `tools/dev_loader.rb` into the SketchUp `Plugins` folder. SketchUp then loads the code from
`C:/prj/fog`. After a change, select **Extensions > FOG > Reload extension (dev)**.

SketchUp 2021 or newer is necessary (tag folders).

## Use the Body button

1. Draw a rectangle on the floor and use Push/Pull to get the height.
2. On the front side, offset the outline 18 mm to the inner side. Use Push/Pull to push the center piece through the shape.
3. Group the geometry. Close the group.
4. In Entity Info, write the unit name in the **Instance** field of the group.
5. Click **Body**. Move the cursor over the group. The tool highlights a valid group in yellow.
   If the group is not valid, the status bar shows the reason.
6. Turn the camera so that the front side faces you, then click the group.
   If the name is empty or not valid, a message shows the reason.
7. Push **Left** or **Right** to select the overlap. The tool shows the panels, and the front side in orange.
8. Push **Enter** or click.

**Esc** goes one step back, and then exits the tool. One **Undo** restores the group.

## Tests

```
ruby test/test_shape.rb
ruby test/test_layout.rb
ruby test/test_names.rb
```

The tests cover the shape check, the panel axes and the name rules. They do not need SketchUp.
The code in `builder.rb` and `body_tool.rb` needs SketchUp, so these tests do not cover it.
