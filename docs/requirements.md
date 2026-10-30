# FOG: requirements

Status: draft. The concept can change during development.

Marks in this document:

- **[Proposed]**: the user did not specify this item. It is a proposed default. Change it if it is not correct.
- **[Q4]**: an open question. See [Open questions](#7-open-questions).

## 1. Purpose

The user draws a simple shape in SketchUp. The plugin changes the shape quickly into a furniture unit and applies
the modeling rules of the user's projects. The result must be ready for
[ocl-joints](https://github.com/agav/ocl-joints), [ocl-viyar](https://github.com/agav/ocl-viyar) and OpenCutList.

## 2. Buttons

The plugin has a toolbar with these buttons. Only button 1 is specified now. The other buttons are placeholders.

| # | Button | Function | Status |
|---|---|---|---|
| 1 | Body | Changes a shape into a body: four panels, tags, scene | Specified in section 3 |
| 2 | Fronts | Adds fronts | Later |
| 3 | Back | Adds a back | Later |
| 4 | Edge bindings | Makes edge bindings | Later |
| 5 | Joints | Places joints | Later |

## 3. Button 1: Body

### 3.1 Input shape

The user makes the shape in these steps:

1. Draw a rectangle on the floor.
2. Use Push/Pull to get the height.
3. On the front side, offset the outline 18 mm to the inner side.
4. Use Push/Pull to push out the center piece.
5. Group the geometry.

The result is one group that has the shape of four connected panels: bottom, left, right and top.

A group is a **valid candidate** if all these conditions are true:

| ID | Condition |
|---|---|
| IN-1 | It is a group. |
| IN-2 | Its outer shape is a rectangular box (all corners are 90°). |
| IN-3 | It has one rectangular through opening between two opposite sides. |
| IN-4 | All four walls around the opening are 18 mm thick. |
| IN-5 | **[Proposed]** The axis of the opening is horizontal, and the walls are vertical or horizontal. The group can turn around the model Z axis. |
| IN-6 | **[Proposed]** The group contains only faces and edges. It has no nested groups or components. Added coplanar edges are permitted. |
| IN-7 | **[Proposed]** The tolerance for dimensions is 0.1 mm. Dimensions are measured in model space, after the group transformation. |
| IN-8 | **[Proposed]** The group is in the model root. Close all groups before you use the tool (same limit as ocl-joints). |

A shape with a blind pocket (the center piece is not pushed through) is not valid. Button 1 makes only the four panels.
The back is a separate operation (button 3), because the back placement can be different on different units.
A later version can combine buttons.

### 3.2 Procedure

1. The user clicks button 1. The select tool starts.
2. The user moves the cursor. The tool highlights a valid candidate under the cursor, the same way ocl-joints
   highlights a panel (yellow edges, 1 px). The tool does not highlight other objects.
3. The user clicks a highlighted candidate.
4. The plugin gets the unit name (section 3.3).
5. The user selects the overlap (section 3.5).
6. The plugin makes the result (sections 3.6 to 3.9).

**[Proposed]**

- **Esc** cancels the current step. Until step 6, the plugin does not change the model.
- The status bar shows the instruction for the current step.
- Step 6 is one undo operation. One **Undo** restores the initial group and removes the new tags, the new tag folder and the new scene.

### 3.3 Unit name

The user gives the name `<name>`.

**[Proposed]** The plugin shows an input field. The field contains the instance name of the initial group (Entity Info > Instance), if it has one.
Thus the user can write the name in Entity Info before the operation and only push **Enter** in the field.

Name rules:

| ID | Rule |
|---|---|
| NM-1 | `<name>` is not in conflict with a name of a tag, tag folder, component definition or scene in the model. Two names are in conflict if they are the same, or if one name starts with the other name plus `-`. |
| NM-2 | **[Proposed]** The name is not empty. Spaces at the start and at the end are removed. |
| NM-3 | The comparison in NM-1 ignores uppercase and lowercase. |
| NM-4 | **[Proposed]** The name does not start with `f_` or `g_`. ocl-joints and ocl-viyar use these prefixes for machining components, not for panels. |

If the name is not valid, the plugin shows the reason and asks again.

The reason for NM-1: all names of a unit are `<name>` or start with `<name>-`. These are the tag folder and the scene `<name>`,
the tags `<name>-<role>` and the components `<name>-<role>-<panel>`. If NM-1 is true, no other unit can have these names.
Later buttons can add tags such as `<name>-front` with no new name check.

Examples for NM-1:

| Exists in the model | New name | Valid? | Reason |
|---|---|---|---|
| Tag `cab1-body` | `cab1` | No | The unit would make the same tag |
| Tag folder `cab1`, tag `cab1-body` | `cab1-front` | No | Button 2 of `cab1` will make the tag `cab1-front` |
| Tag `cab10-body` | `cab1` | Yes | `cab1-body` is a different name |
| Tag `cab1-body` | `cab10` | Yes | `cab10-body` is a different name |
| Tag `body 18 white` | `body` | Yes | The name after `body` does not start with `-` |

A later button can find a tag with its name that the user added by hand after the unit was made. Example: `cab1-front`.

- If this tag is in the tag folder of the unit, the button uses it.
- If this tag is not in the tag folder of the unit, the button stops and shows a message.

### 3.4 Front side and unit frame

The **front side** is the side with the opening that faces the user. Because the opening goes through the shape,
two sides have an opening. The plugin selects the side with the outward normal that points most directly to the camera.

**[Proposed]** The plugin finds this side when the user clicks the candidate. If the camera looks along the plane of the opening
and the plugin cannot select a side, the plugin asks the user to turn the camera.

All directions in this document are as seen from the front of the unit:

| Direction | Definition |
|---|---|
| Back | Opposite to the outward normal of the front side |
| Top | Model Z axis |
| Right | Back × Top |

Thus Right, Back and Top are a right-handed frame. In this document:

- Coordinates are `(x, y, z)` in this frame: x to the right, y to the back, z to the top.
- The point `(0, 0, 0)` is the left, front, bottom corner of the outer box.
- `W` is the width, `D` is the depth, `H` is the height, and `t` is the panel thickness (18 mm).

### 3.5 Overlap

Two options are available. The panels of the covering pair go across the full outer size.
The panels of the other pair are between them.

| Option | Top and bottom | Left and right |
|---|---|---|
| **A: top and bottom cover the sides** | Length `W` | Length `H − 2t` |
| **B: sides cover top and bottom** | Length `W − 2t` | Length `H` |

```
     Option A                Option B

 +--------------+        +--+--------+--+
 |     top      |        |  |  top   |  |
 +--+--------+--+        |  +--------+  |
 |  |        |  |        |  |        |  |
 |L |        | R|        |L |        | R|
 |  |        |  |        |  |        |  |
 +--+--------+--+        |  +--------+  |
 |    bottom    |        |  | bottom |  |
 +--------------+        +--+--------+--+
```

The user selects the option with the **Left** and **Right** arrow keys, the same way the user selects a connector in ocl-joints.

**[Proposed]**

- The tool shows the joint lines of the current option and marks the front side on the candidate.
- **Enter** or a left click accepts the option.
- The tool starts with the last used option. The first time, the tool starts with option A.

### 3.6 Panels

The plugin replaces the initial geometry with four panels. Each panel is a component:

| Panel | Component definition name |
|---|---|
| Left | `<name>-body-left` |
| Right | `<name>-body-right` |
| Top | `<name>-body-top` |
| Bottom | `<name>-body-bottom` |

All panels have the depth `D` and the thickness `t`.

### 3.7 Panel axes

The axes are important for two reasons:

- The covering material has a texture. The texture direction on a panel follows the axes.
- ocl-joints and ocl-viyar calculate all positions from the axes.

Rules for all panels:

- The origin is on the front face of the unit.
- The red and green axes are in the plane of the panel. The green axis points to the back.
- The blue axis is in the direction of the panel thickness.

When you look at the unit from the front, you see the front edge of each panel. On this edge:

| Panel | Origin | Red axis | Green axis | Blue axis (calculated) |
|---|---|---|---|---|
| Left | Top left corner | Down | Back | Right |
| Top | Bottom left corner | Right | Back | Up |
| Right | Bottom right corner | Up | Back | Left |
| Bottom | Bottom left corner | Right | Back | Up |

The blue axis is calculated: SketchUp axes are right-handed, thus blue = red × green.
On all panels, the material is on the positive side of the blue axis (from 0 to `t`).
The right panel is the left panel turned 180°.

Panel origins in the unit frame:

| Panel | Option A | Option B |
|---|---|---|
| Left | `(0, 0, H − t)` | `(0, 0, H)` |
| Top | `(0, 0, H − t)` | `(t, 0, H − t)` |
| Right | `(W, 0, t)` | `(W, 0, 0)` |
| Bottom | `(0, 0, 0)` | `(t, 0, 0)` |

### 3.8 Materials and tags of the panels

Each panel instance gets:

- The material of the initial group.
- The tag of the initial group.

**[Proposed]**

- The geometry in a panel definition has no material and no tag (Untagged). Thus it shows the instance material,
  and the texture follows the panel axes.
- If the initial group has no material, but all its faces have one material, the panels get this material.
  In other cases, the panels have no material.
- If the initial group is Untagged, the panels are Untagged.

### 3.9 Tags, group and scene

The plugin makes these objects:

| ID | Result |
|---|---|
| RS-1 | A tag folder with the name `<name>`. |
| RS-2 | A tag with the name `<name>-body` in this folder. |
| RS-3 | A new group that contains the four panels. Its tag is `<name>-body`. |
| RS-4 | The new group replaces the initial group. The initial group is erased. |
| RS-5 | A new scene. In this scene, only the `<name>` tag folder (with its tags) and the tag of the initial group are visible. All other tags are hidden. |

**[Proposed]**

- The new group has the instance name `<name>-body` (Entity Info > Instance). It is in the parent of the initial group. Its axes are the unit frame of section 3.4.
- The new scene has the name `<name>` and becomes the active scene. It keeps the current camera.

Result:

```
<name>-body                 group, tag <name>-body
├── <name>-body-left        component, tag and material of the initial group
├── <name>-body-right       component, tag and material of the initial group
├── <name>-body-top         component, tag and material of the initial group
└── <name>-body-bottom      component, tag and material of the initial group
```

## 4. Agreement with the modeling convention

The result agrees with the convention of the user's projects: a unit is a set of top-level groups, a group contains
panels, a panel is a component, the group tag identifies the unit and role, and the panel tag identifies the material class.

The panel definition names are new. The older projects use `<unit>-<role>` (example: `an_lcab-left`). This plugin uses
`<name>-body-<role>`.

## 5. Agreement with the other plugins

- ocl-joints: a panel is a group or component with faces of its own and a name that does not start with `f_` or `g_`.
  ocl-joints calculates the panel box from the definition axes. The geometry of each panel must align with its axes.
- ocl-viyar: it calculates the panel frame from the definition bounds, not only from the origin.

## 6. Technical constraints

- **[Proposed]** Minimum version: SketchUp 2021, because tag folders start in this version. The test version is SketchUp 2026.
- **[Proposed]** The repository has the same layout as ocl-joints: `src/`, `test/`, `tools/build_rbz.py`, `tools/dev_loader.rb`,
  and the menu item **Reload extension (dev)**.
- **[Proposed]** The geometry calculations are in code that does not need SketchUp, so that tests can run without it.

## 7. Open questions

Closed questions:

- Q1 (right panel origin): the origin is the bottom right corner. See section 3.7.
- Q2 (blind pocket): not a valid candidate. See section 3.1.
- Q3 (name rule): a conflict is a same name, or a name that starts with the other name plus `-`. See section 3.3.

### Q4. Buttons 2 to 5

Specify later. Button 5 must also agree with ocl-joints: does it call ocl-joints, or does it have its own function?
