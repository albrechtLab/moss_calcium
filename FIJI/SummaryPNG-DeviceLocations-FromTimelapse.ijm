
run("Set Scale...", "distance=0.345 known=1 unit=µm");
run("Properties...", "channels=1 slices=1 frames=3600 pixel_width=2.8986 pixel_height=2.8986 voxel_depth=2.8986 frame=[1 sec]");
run("Z Project...", "projection=[Max Intensity]");
run("Scale Bar...", "width=200 height=200 thickness=10 font=24 location=[Lower Left] overlay");
run("Enhance Contrast", "saturated=0.35");
run("Enhance Contrast", "saturated=0.35");
run("Enhance Contrast", "saturated=0.35");
// saveAs(format, path);