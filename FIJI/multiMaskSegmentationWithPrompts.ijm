#@ File (label = "Input Expirement File", style="open") inputFile
#@ File (label = "Save Directory", style="directory") saveDirectory

function maxProject(imgName) {
	/*
	 * 		Max Z-Project & rename generated window for consistency
	 */
	selectWindow(imgName);
	run("Z Project...", "projection=[Max Intensity]");
	selectWindow("MAX_"+imgName);
	rename("max-projection");
	run("Enhance Contrast", "saturated=0.35");
	}

function genBackground(blurRadius) {
	/*
	 * 		Generate background to remove from the maximum projection
	 */

	selectWindow("max-projection");
	run("Duplicate...", " ");
	rename("background");
	run("Gaussian Blur...", "sigma="+toString(blurRadius));
	run("Enhance Contrast", "saturated=0.35");
}
function removeBackground() {
	/*
	 * 		Divide background out of projection (32-bit) , convert result
	 * 		back to 16-bit, rename result & close unecessary windows
	 */
	imageCalculator("Subtract create 32-bit", "max-projection","background");
	selectWindow("Result of max-projection");
	rename("background-removed");
	run("Enhance Contrast", "saturated=0.35");
	// Convert back to original image type
	setOption("ScaleConversions", true);
	run("16-bit");
}
function genBinaryMask() {
	/*
	 * 		Filter and threshold image to get a binary mask
	 */
	selectWindow("background-removed");
	run("Duplicate...", " ");
	// Median for smoothing & edge retention
	run("Median...", "radius=2.5");
	// setAutoThreshold("Triangle dark");
	rename("binary-mask");
	setAutoThreshold("MinError dark no-reset");
	run("Convert to Mask");
	run("Enhance Contrast", "saturated=0.35");
	setAutoThreshold("MinError dark no-reset");
}
function getROI() {
	// selectWindow("binary-mask");
	run("Analyze Particles...", "size=200-Infinity circularity=0.00-0.7 clear overlay add composite");
	// run("Analyze Particles...", "size=200-Infinity circularity=0.00-0.9 clear overlay add composite");
}
function saveImages(saveDirectory, imgName, image) {
	/*
	 * 		Save the image (image window name) to the save directory
	 */
	saveName = saveDirectory + File.separator + imgName + "_" + image + ".ome.tif";
	selectWindow(image);
	save(saveName);
	IJ.log("Saved " + saveName);
}
function ask2Save() {
	// User Dialog -- save the really big stack?
	answer = getBoolean("Save Generated Images?");

	if(answer==true) {
		// Save all newly generated images
		// saveROI(saveDirectory, newName);
		// saveImages(saveDirectory, newName, "max-projection");
		// saveImages(saveDirectory, newName, "background-removed");
		// saveImages(saveDirectory, newName, "binary-mask");
		saveImages(saveDirectory, newName, "combo");
	} else {
	IJ.log("Generated Images Not Saved!");
	}
}

// Open input file unless exactly 1 image is open -- added 2022-05-25 by VK
if (nImages!=1) {
	// Close all open windows
	close("*");
	// Open image & log filepath
	IJ.log("Opening images located at: " + inputFile);
	run("Bio-Formats Importer", "open=[" + inputFile + "] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
}

if (roiManager("count") > 0) {
	/*
	 * 	Reset if ROI in manager already
	 */
	roiManager("reset");
}

// Grabbing image name for logging
imgName = getTitle();// getInfo("image.filename"); // Changed 2022-07-25 by VK getInfo("image.directory"); File.getName(inputFile);
if (endsWith(imgName, ".ome.tif")){
	newName = substring(imgName, 0, lengthOf(imgName)-8);
}
else if (endsWith(imgName,".tif")) {
	// newName = substring(imgName, 0, lengthOf(imgName)-4);
	newName = substring(imgName, 0, lengthOf(imgName)-8);
}
else {
	newName = imgName;
}

// Make sure the scale is correct
run("Set Scale...", "distance=0.345 known=1 unit=micron");

// Rename window minus file type
selectWindow(imgName);
run("Enhance Contrast", "saturated=0.35");
rename(newName);
IJ.log("Imported " + newName);

// Create binary masks using 5 diff. radius' for background subtraction
// 		larger rad -> larger # of foreground pixels (incr. FPs)
radii = newArray(10,25,40,55,70); 

// Run processing steps
for (i = 0; i < lengthOf(radii); i++) {
	// Run processing steps
	maxProject(newName);
	
	blurRadius = radii[i];
	
	genBackground(blurRadius);
	
	removeBackground();
	
	genBinaryMask();
	
	getROI();
	close("background-removed"); close("background"); close("max-projection"); close("max-projection");
	
	// clear non-selected regions
	roiManager("select",0); run("Clear Outside");
	
	// Set segmented region == 1
	setForegroundColor(1, 1, 1);
	for (j = 0; j<roiManager("count"); j++){
		roiManager("select", j);
		roiManager("Fill"); 
	}
	run("Enhance Contrast", "saturated=0.35");

	// Save each generated mask
	rename("binary-mask"+toString(blurRadius)+".tif");
	// saveAs("Tiff", "Z:/UndergradRemoteProjects/TRIAD-MossProject/Vanessa/Analysis/30MinStimulation1Repeat/3HourAcclimation/WIP 2023-11-05/Individual Plants/2/binary-mask"+toString(blurRadius)+".tif");
	
	// close("*");
	// close();
}

// Combine all binary masks
imageCalculator("Add create", "binary-mask10.tif","binary-mask25.tif");
selectWindow("Result of binary-mask10.tif");
rename("combo");
imageCalculator("Add", "combo","binary-mask40.tif");
imageCalculator("Add", "combo","binary-mask55.tif");
imageCalculator("Add", "combo","binary-mask70.tif");
run("Enhance Contrast", "saturated=0.35");

// pixel needs to be in > half of masks to be kept
// setThreshold(3, 255);//
setThreshold(2, 255);
run("Convert to Mask");
// get ROI
run("Analyze Particles...", "size=200-Infinity circularity=0.00-0.90 clear overlay add composite");
run("Open");

// Ask user if they'd like to save generated files
ask2Save();

// Tile generated images for viewing purposes
run("Tile");

// close("*");
