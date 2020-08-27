# Collection of editor scripts
 Custom menu items for Defold editor to enhance development workflow.
 [Manual](https://defold.com/manuals/editor-scripts/)

## Z-order.editor_script:

**Z = -Y**
sets Z coord as -Y/1000. Useful for an isometric scene.

**Z-order (sort by Y)**
sort objects by Z-coord, uses Y-coord as comparison value.

**Swap Z**
swap Z-coord between two selected objects.

**Shift DOWN** and **Shift UP**
shanges Z-coord on offset value.

To setup your own offset value change this:
```
	local Z_OFFSET = 0.01
```

**Horizontal Flip** sets rotation of object to 180 degrees or 0 if already rotated.

**Reset Transform** fully resets transformation matrix of selected object.