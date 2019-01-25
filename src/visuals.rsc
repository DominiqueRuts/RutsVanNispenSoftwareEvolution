/*
 * course : Software Evolution (IM0202) Assignment 2: Software Visualization
 * authors: Johan van Nispen (836541627) and Dominique Ruts (852059122)
 * date   : 18/01/2019
 */

module visuals

import List;
import qprofile;
import metrics;
import vis::Figure;
import vis::Render;
import vis::KeySym;

import Relation;
import String;
import Map;
import Set;

import util::Math;
import IO;

// defined types to hold visualization data
alias ProjectFilesStats = list[tuple[str file, str path, int size, int complexity, int methodCount, int riskcc, int maxriskcc]];
alias ProjectFilesStat = tuple[str file, str path, int size, int complexity, int methodCount, int riskcc, int maxriskcc];
alias ProjectFilesPath = map[str file, str path];
alias ProjectFilesSize = map[str file, int size];
alias ProjectFilesMethods = map[str file, int methods];
alias ProjectFilesRiskCC = map[str file, int riskCC];
alias ProjectFilesMaxRiskCC = map[str file, int maxriskcc];
alias ProjectFilesComplexity = map[str file, int complexity];

private int complexityFilter = 1;
private real maxComplexityLog = 0.0;
// private variables to identify which Risk CC checkbox is checked
private bool veryHighRisk = false;
private bool highRisk = false;
private bool moderateRisk = false;
private bool lowRisk = false;
// private variables to enable Accessibility mode
private bool colorblindview = false;
private str veryHighRiskStyle = "solid";
private str highRiskStyle = "solid";
private str moderateRiskStyle = "solid";
private str lowRiskStyle = "solid";
// private variable to hold the clicked bubble details
private ProjectFilesStat clickedFileStat = <"", "", 0, 0, 0, 0, 0>;

// main function to build up and display the high level project information
public void displayDashboard(ProjectSummary psum, list[MethodStat] ProjectStat_sorted_loc) {
	
	// get project file statistics
	ProjectFilesStats pfs = getProjectFileStats(ProjectStat_sorted_loc);
	list[MethodStat] pms = ProjectStat_sorted_loc;
	
	str pname = psum.projectname + " - dashboard";
	Figure top      = getTop(psum);
	Figure middle_t = getMiddleTop(); 
	Figure middle_b = getMiddleBottom(psum);
	Figure bottom_t = getBottomTop();
	Figure bottom   = getBottom(psum);
	Figure bottom_b = getBottomBottom(psum, pfs, pms);
	
	render(pname, vcat([top, middle_t, middle_b, bottom_t, bottom, bottom_b]));
}

public Figure getTop(ProjectSummary psum) {
	str pname = "Project Overview \'" +  psum.projectname + "\'";	
	Figure b1  = box( text(pname, fontSize(20), fontBold(true)), std(halign(0.075)) );
	Figure b2a = box( text("Overall Rating", fontSize(20), fontBold(true)), std(halign(0.3)) );
	Figure b2b = getRating(psum.total_rating);
	Figure b2  = box( hcat([b2a, b2b]) );
	
	return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"), std(lineColor("white")));
}

public Figure getMiddleTop() {
	Figure b1 = box( text("Code Metrics (SiG Criteria)", fontSize(20)), std(halign(0.06)) );
	Figure b2 = box( text("ISO9126 Quality Rating", fontSize(20)), std(halign(0.1)) );
	
	return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"), std(lineColor("white")));
}

public Figure getMiddleBottom(ProjectSummary psum) {
	Figure b1 = getRatingMatrix("Volume", "Code Duplication", "Unit Size", "Unit Complexity", psum.vol_rating, psum.dup_rating, psum.size_rating, psum.cc_rating);
	Figure b2 = getRatingMatrix("Analysability", "Changability", "Stability", "Testability", psum.analysability, psum.changability, psum.stability, psum.testability);
	
	return box(hcat([b1, b2]), vshrink(0.35), fillColor("white"), std(lineColor("white")));
}

public Figure getBottomTop() {	
	Figure b1 = box( text("Unit Size", fontSize(20)) );
	Figure b2 = box( text("Unit Complexity", fontSize(20), halign(0.05)) );
	Figure b3 = box( text("Architecture", fontSize(20), halign(0.03)) );
	
	return box(hcat([b1, b2, b3]), std(halign(0.05)), vshrink(0.1), std(fontBold(true)), fillColor("white"), std(lineColor("white")));
}

alias ScaleTable = tuple[real s_low, real s_mod, real s_hig, real s_vhi];

public Figure getBottom(ProjectSummary psum) {

	// calculate scaling and offset for size diagram
	ScaleTable st = getScaling(psum.size_profile, 0.1);
		
    Figure L0 = box(hshrink(0.015), fillColor("white"));
                     
    Figure L = hcat([box(hshrink(st.s_low), fillColor("Green"), lineColor("Green"), popup("low risk: <psum.size_profile.low_per>%")), 
					 box(hshrink(st.s_mod), fillColor("Yellow"), lineColor("Yellow"), popup("moderate risk: <psum.size_profile.moderate_per>%")),
					 box(hshrink(st.s_hig), fillColor("Orange"), lineColor("Orange"), popup("high risk: <psum.size_profile.high_per>%")),
					 box(hshrink(st.s_vhi), fillColor("Red"), lineColor("Red"), popup("very high risk: <psum.size_profile.very_high_per>%"))
 					 ]);
 	
	// calculate scaling and offset for complexity diagram
	st = getScaling(psum.cc_profile, 0.1);
	
	Figure C = hcat([box(hshrink(st.s_low), fillColor("Green"), lineColor("Green"), popup("low risk: <psum.cc_profile.low_per>%")), 
					 box(hshrink(st.s_mod), fillColor("Yellow"), lineColor("Yellow"), popup("moderate risk: <psum.cc_profile.moderate_per>%")),
					 box(hshrink(st.s_hig), fillColor("Orange"), lineColor("Orange"), popup("high risk: <psum.cc_profile.high_per>%")),
					 box(hshrink(st.s_vhi), fillColor("Red"), lineColor("Red"), popup("very high risk: <psum.cc_profile.very_high_per>%"))
					]);
							 
	Figure R = vcat([box(text("Files		: <psum.files>", fontSize(20)), std(left())), 
					 box(text("Methods	: <psum.methods>", fontSize(20)), std(left())), 
					 box(text("Lines of Code	: <psum.volume>", fontSize(20)), std(left()))]);
	
	return box(hcat([L0, L, C, R]), vshrink(0.25), fillColor("white"), std(lineColor("white")));
}

public ScaleTable getScaling(RiskProfile rp, real offset) {
	real al = offset;
	real sc = (1.0 - al) - al; 
	
	real s_low = sc*(rp.low_per/100.0);
	real s_mod = sc*(rp.moderate_per/100.0);
	real s_hig = sc*(rp.high_per/100.0);
	real s_vhi = sc*(rp.very_high_per/100.0);
	
	return <s_low, s_mod, s_hig, s_vhi>;
}

public Figure getBottomBottom(ProjectSummary psum, ProjectFilesStats pfs, list[MethodStat] pms) {	
	int a = 200, b = 30, c = 125, n = 0;
	 
	Figure b1 = box(button("Unit Size Treemap", void(){displayUnitSize(psum, pms);}, halign(0.075), size(a, b), resizable(false, false)));
	Figure b2 = box(button("File Size Treemap", void(){displayFileSize(psum, pfs);}, halign(0.05), size(a, b), resizable(false, false)));
	
	Figure b3a = button("Complexity", void(){displayCCDist(psum, pfs);}, halign(0.1), size(c, b), resizable(false, false));
	Figure b3b = button("Partitioning", void(){displayIcicleTree(psum, pfs);}, halign(0.4), size(c, b), resizable(false, false));
	
	Figure b3 = box(hcat([b3a, b3b]));
	
	return box(hcat([b1, b2, b3]), vshrink(0.1), fillColor("white"), std(lineColor("white")));
}

public Figure getRatingMatrix(str drow1, str drow2, str drow3, str drow4, int rrow1, int rrow2, int rrow3, int rrow4) {
	real al = 0.1;
	row1 = [box(text(drow1, fontSize(15), right())), getRating(rrow1)];
	row2 = [box(text(drow2, fontSize(15), right())), getRating(rrow2)];
	row3 = [box(text(drow3, fontSize(15), right())), getRating(rrow3)];
	row4 = [box(text(drow4, fontSize(15), right())), getRating(rrow4)];
	
	return box(grid([row1, row2, row3, row4]));
}

public Figure getRating(int rating) {
	str col = "white", rcol = "white";
	list[Figure] l = [];
	
	if (rating == 1) rcol = "DarkRed";
	if (rating == 2) rcol = "Red";
	if (rating == 3) rcol = "Orange";
	if (rating == 4) rcol = "Yellow";
	if (rating == 5) rcol = "Green";
	
	for (a <- [0..5]) {
		if ((a+1) == rating) {
			col = rcol;
		}
		else {
			col = "white";
		}
		l += ellipse(fillColor(col), lineColor("black"), size(25), resizable(false, false)); 
	}
	return box(hcat(l), center());
}

// returns color for risk category of unit size or unit complexity
public str getColor(int risk) {
	str rcol = "white";

	if (risk <= 1) rcol = "Green";
	if (risk == 2) rcol = "Yellow";
	if (risk == 3) rcol = "Orange";
	if (risk >= 4) rcol = "Red";
	
	return rcol;
}

public Figure getHeaderView(ProjectSummary psum, str a, str b) {	
	Figure b1  = box( text(a, fontSize(20), fontBold(true)), std(halign(0.075)) );
	Figure b2 = box( text(b, fontSize(12)) );

	return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"), std(lineColor("white")));
}

public void displayUnitSize(ProjectSummary psum, list[MethodStat] ProjectStat_sorted_loc) {
	str pname = psum.projectname + " - unit size treemap";
	list[MethodStat] pms = ProjectStat_sorted_loc;	
	t = treemap([ box(area(s.size), fillColor(getColor(s.risk_cc)), popup("Method: <s.name>\nSize: <s.size>\nComplexity: <s.complexity>")
                 , execOnMouseDown("name: <s.name>, size: <s.size>, complexity: <s.complexity>") ) | s <- pms, s.size > 15
                ], vshrink(0.9), hshrink(0.975));
                
	render(pname, vcat([getHeaderView(psum, "Unit Size Treemap", "box area = unit size, box color = unit complexity"), t]));
}

public void displayFileSize(ProjectSummary psum, ProjectFilesStats pfs) {
	str pname = psum.projectname + " - file size treemap";
	cscale = colorScale(pfs.complexity, color("green"), color("darkred"));
    t = treemap([ box(area(s.size), fillColor(cscale(s.complexity)), popup("Filename: <s.file>\nSize: <s.size>\nComplexity: <s.complexity>")
                , execOnMouseDown("name: <s.file>, size: <s.size>, complexity: <s.complexity>") ) | s <- pfs, s.size > 15
                ], vshrink(0.9), hshrink(0.975));
                
	render(pname, vcat([getHeaderView(psum, "File Size Treemap", "box area = file size, box color = file complexity"), t]));
}

public void displayFileRisk(ProjectSummary psum, ProjectFilesStats pfs) {
	str pname = psum.projectname + " - file risk level treemap";
    t = treemap([ box(area(s.size), fillColor(getColor(s.maxriskcc)), popup("Filename: <s.file>\nFile size (LOC): <s.size>\nRisk level (max.): <s.maxriskcc>")
                , execOnMouseDown("filename: <s.file>, file size: <s.size>, risk level (max.): <s.maxriskcc>") ) | s <- pfs, s.size > 10
                ], vshrink(0.9), hshrink(0.975));
                
	render(pname, vcat([getHeaderView(psum, "File Risk Level Treemap", "box area = file size, box color = max. risk level"), t]));
}

public void displayCCDist(ProjectSummary psum, ProjectFilesStats pfs) {
	str pname = psum.projectname + " - complexity distribution";
	render(pname, vcat([getHeaderViewDist(pfs), scaledCircles(pfs), box(vshrink(0.01), fillColor("white"), std(lineColor("white")))]));
}

public void displayIcicleTree(ProjectSummary psum, ProjectFilesStats pfs) {
	str pname = psum.projectname + " - source code partitioning chart";
	render(pname, vcat([getHeaderViewIcicle(pfs), scaledIcicle(pfs, psum.projectname)]));
}

public Figure getHeaderViewIcicle(ProjectFilesStats pfs) {
	int maxComplexity = max(pfs.complexity);
	Figure b1 = box( text("Source Code Partitioning Chart", fontSize(20), fontBold(true)), std(halign(0.045)) );
	Figure b2 = checkColorBlind();
	Figure b3 = check();
	
	return box(hcat([b1, b2, b3]), vshrink(0.1), fillColor("white"), std(lineColor("white")));
}

public Figure getHeaderViewDist(ProjectFilesStats pfs) {
	int maxComplexity = max(pfs.complexity);
	Figure b1 = box( text("File Complexity Distribution", fontSize(20), fontBold(true)), std(halign(0.15)) );
	Figure b2 = hcat([ text(str () { return "Complexity Filter (min.): <complexityFilter>";}, fontSize(12)),
   				 	   createComplexitySlider(maxComplexity)                       
					], std(left()), resizable(false));
	
	Figure b3 = checkColorBlind();
	
	return box(hcat([b1, b2, b3]), vshrink(0.1), fillColor("white"), std(lineColor("white")));
}

Figure scaledCircles(ProjectFilesStats pf){
	int maxFileSize = max(pf.size);
	int maxMethodCount = max(pf.methodCount);
	int maxComplexity = max(pf.complexity);
	maxComplexityLog = log(maxComplexity,2);

   return vcat([
   			hcat ([
   				text("Methods", fontBold(true), textAngle(270)),   				
   				vcat([  
					hcat([grid(
						[
						 [createYAxis(maxMethodCount), createBubbleChart(maxFileSize, maxMethodCount, maxComplexity, pf)],
						 [box(width(20),resizable(false), left()), createXAxis(maxFileSize)]						
						], resizable(true), left(), gap(2)),
						vcat([
							check()
						], resizable(false), top(), left(), gap(5))                   
					], top())                
				] )
			]), text("File size (LOC)", fontBold(true), halign(0.4)), computeFigure(Figure (){return fileDetails();}) 
		], gap(5));
}

data LevelMap = LevelMap(str name, list[LevelMap] children, int maxriskcc, int size);

Figure scaledIcicle(ProjectFilesStats pf, str project){
	LevelMap lmp2 = readLoc("<project>/src");
	
	return computeFigure(Figure (){ return LevelMapGrid(lmp2);});	
}

Figure LevelMapGrid(LevelMap lm) {
	return grid([[box(text(lm.name), std(lineColor("white")), height(30))], [LevelMapItem(lm.children)]], top(), resizable(false));
}

Figure LevelMapItem(list[LevelMap] li) {
	list[value] lg = [];
	for (i <- li) {
		if (i.children == []) {
			lg += grid([[box(width(sqrt(i.size)), height(150), lineColor(colorblindview ? "black":"white"),
			  fillColor(getRiskColor(i.maxriskcc)), align(0), resizable(false),
				popup("File: <i.name>\nSize: <i.size>\nRisk level (max.): <i.maxriskcc>"))] | i.maxriskcc == getVeryHighRisk() ||
				 i.maxriskcc == getHighRisk() || i.maxriskcc == getModerateRisk() || i.maxriskcc == getLowRisk() || getDefaultRisk() == 0], 
				  top());
		} else {
			if (!isEmptyLevelMap(i[1])) {
				lg += grid([[box(text(substring(i.name,findLast(i.name,"/")+1), width(5), textAngle(90), fontSize(8)), width(5), 
				      height(150), fillColor(color("blue", 0.3)), std(lineColor("white")), size(10), align(0), resizable(true))], 
				       [LevelMapItem(i.children)]], resizable(false), top());
			}
		}
	}
	
	return grid([lg]);
}

private bool isEmptyLevelMap(list[LevelMap] l) {
	if (isEmpty(l) || (isEmptyLevelMap(l[0].children)) && !endsWith("<l[0].name>",".java")) {
		return true; 
	} else {
		return false;
	}
}

private int maxSize = 0;

private LevelMap readLoc(str name) {
	loc lc = toLocation("project://<name>");
	list[str] files = listEntries(lc);
	
	list[LevelMap] tmp = [];	
	
	for(f <- files) {
		str filePath = "<name>/<f>";
		if (isDirectory(toLocation("project://<filePath>"))) {
			tmp += readLoc(filePath);			
		} else if(isFile(toLocation("project://<filePath>")) && endsWith(filePath, ".java")) {
			str filteredName = substring(getFileName("<filePath>/"),0,findLast(getFileName("<filePath>/"),"."));
			int mrc = (size(domainR(pfmaxriskcc, {filteredName})) > 0 ? pfmaxriskcc[filteredName]: 1);			
			int size = (size(domainR(pfsize, {filteredName})) > 0 ? pfsize[filteredName]: 1);
			maxSize = size > maxSize ? size : maxSize;
			tmp += LevelMap(filePath, [], mrc, size);
		}
	}

	return LevelMap(name, tmp, 0, 0);
}

Figure createComplexitySlider(int max) {
	return scaleSlider(int() { return 1; },     
                                    int () { return max; },  
                                    int () { return complexityFilter; },    
                                    void (int s) { complexityFilter = s; }, 
                                    width(350));
}

Figure createXAxis(int max) {
	return grid([[box(text("|\n<toInt(pow(2,round(g)))>",ialign(0.5)),height(30),gap(1),resizable(false), left(),lineWidth(0)) | g <- [0.. log(max,2)]]]);
}

Figure createYAxis(int max) {
	return grid([[box(text("<g>-"),height(30),resizable(false), bottom(),lineWidth(0))] | g <- [max..0], remainder(toRat(g,20)) == 0], vgap(30),resizable(false), left());
}

Figure createBubbleChart(int maxFileSize, int maxMethodCount, int maxComplexity, ProjectFilesStats pf) {
	return computeFigure(Figure (){ return box(overlay([createEllipse(maxFileSize, maxMethodCount, maxComplexity, s) | s <- pf, s.complexity > complexityFilter-1, 
		s.maxriskcc == getVeryHighRisk() || s.maxriskcc == getHighRisk() || s.maxriskcc == getModerateRisk() || s.maxriskcc == getLowRisk() || getDefaultRisk() == 0])); });
}

Figure createEllipse(int maxFileSize, int maxMethodCount, int maxComplexity, ProjectFilesStat s) {
	return ellipse(size(sqrt(s.complexity)*3), align(log(s.size,2)/log(maxFileSize, 2),1-toReal(s.methodCount)/maxMethodCount), 
	  fillColor(getRiskColor(s.maxriskcc)), lineStyle(getRiskLineStyle(s.maxriskcc)), lineWidth(getRiskLineWidth(s.maxriskcc)), 
	    resizable(false), ellipseMouseDown(s));
}

public int getDefaultRisk() {
	if (veryHighRisk)  return 4; 
	if (highRisk)  return 3;
	if (moderateRisk)  return 2;
	if (lowRisk) return 1;
	return 0;
}

public int getVeryHighRisk() {
	if (veryHighRisk)  return 4; 
	return 0;
}

public int getHighRisk() {
	if (highRisk)  return 3; 
	return 0;
}

public int getModerateRisk() {
	if (moderateRisk)  return 2; 
	return 0;
}

public int getLowRisk() {
	if (lowRisk)  return 1; 
	return 0;
}

public Color getRiskColor(int risk) {
	str col = "grey";

	if (risk == 4) col = "red"; 
	if (risk == 3) col = "orange";
	if (risk == 2) col = "yellow";
	if (risk == 1) col = "green";
	
	if (colorblindview) {
		if (risk == 4) col = "black"; 
		if (risk == 3) col = "dimgray";
		if (risk == 2) col = "lightgray";
		if (risk == 1) col = "whitesmoke";
	}
	
	return color(col, 0.6);
}

public Figure check(){
  bool state = false;
  //return vcat([ text("Risk Level Filter", fontSize(12), halign(0.4)),
  return vcat([ text("Risk Level Filter", fontSize(12), halign(0.1)),
  				checkbox("4 - Very High", void(bool s4){ state = s4; if(s4) {veryHighRisk = true; } else {veryHighRisk = false;}}, fillColor("red"), left(), width(150), resizable(false)),
  				checkbox("3 - High", void(bool s3){ state = s3; if(s3) {highRisk = true; } else {highRisk = false;}}, fillColor("orange"), left(), width(150), resizable(false)),
  				checkbox("2 - Moderate", void(bool s2){ state = s2; if(s2) {moderateRisk = true; } else {moderateRisk = false;}}, fillColor("yellow"), left(), width(150), resizable(false)),
  				checkbox("1 - Low", void(bool s1){ state = s1; if(s1) {lowRisk = true; } else {lowRisk = false;}}, fillColor("green"), left(), width(150), resizable(false))
              ], width(150), resizable(false), top());
}

public str getRiskLineStyle(int risk) {
	if (risk == 4) return veryHighRiskStyle; 
	if (risk == 3) return highRiskStyle;
	if (risk == 2) return moderateRiskStyle;
	if (risk == 1) return lowRiskStyle;
	
	return "solid";
}
 
public int getRiskLineWidth(int risk) {
	return colorblindview ? 3 : 1;
}

public Figure checkColorBlind(){
  bool colorblind = false;
  return checkbox("Color Blind View", void(bool s){ colorblind = s; if(s) {colorblindview = true; veryHighRiskStyle = "dashdot"; highRiskStyle = "dash"; moderateRiskStyle = "dot"; lowRiskStyle = "solid"; } 
  else {colorblindview = false; veryHighRiskStyle = "solid"; highRiskStyle = "solid"; moderateRiskStyle = "solid";lowRiskStyle = "solid";}}, left(), width(150), resizable(false));
}

public Figure fileDetails(){
  bool state = false;
  
  r1 = [box(text("Filename: ", right())), box(text("<clickedFileStat.file>")),
        box(text("Risk level (max.): ", right())), box(text("<clickedFileStat.maxriskcc == 0 ? "" : clickedFileStat.maxriskcc>"))
        ];
  r2 = [box(text("Path: ", right())), box(text("<clickedFileStat.path>")), 
  		box(text("Methods: ", right())), box(text("<clickedFileStat.methodCount == 0 ? "" : clickedFileStat.methodCount>"))
  		];
  r3 = [box(text("File size (LOC): ", right())), box(text("<clickedFileStat.size>")),
  		box(text("Complexity (sum): ", right())), box(text("<clickedFileStat.complexity == 0 ? "" : clickedFileStat.complexity>"))
  		];
  
  return hcat([box(text("File details", top(), right(), fontSize(10), fontBold(true)), hshrink(0.1)), 
               grid([r1, r2, r3])], std(lineColor("white")), top(), vshrink(0.075), std(fontSize(9)), width(750), std(left()));
}

public Figure complexityfield(){
  return vcat([ box(textfield("<complexityFilter>", void(str s){ complexityFilter = toInt(s);}, fillColor("yellow")), fillColor("yellow"), width(50), resizable(false))
              ]);
}  

FProperty popup(str S){
 return mouseOver(box(text(S), size(50), fillColor("lightyellow"),
 grow(1.2),resizable(false)));
}

FProperty ellipseMouseDown(ProjectFilesStat s) {
	return onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {                                                   
                                                 clickedFileStat = s;
                                                 return true; //fileName = fn;
                                             } );
}

FProperty execOnMouseDown(str info) {
return onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
     println("<info>");
     return true;
  });
}

ProjectFilesSize pfsize = ();
ProjectFilesMaxRiskCC pfmaxriskcc = ();

private ProjectFilesStats getProjectFileStats(list[MethodStat] ProjectStat_sorted_loc) {
	ProjectFilesStats pfs = [];
	ProjectFilesPath pfpath = ();
	pfsize = ();
	ProjectFilesMethods pfmethods = ();
	ProjectFilesRiskCC pfriskcc = ();
	pfmaxriskcc = ();
	ProjectFilesComplexity pfcomplexity = ();
	
	for (s <- ProjectStat_sorted_loc) {
		if(getFileName(s.name) in pfsize) {			
			pfsize[getFileName(s.name)] = pfsize[getFileName(s.name)] + s.size;
			pfmethods[getFileName(s.name)] += 1;
			pfriskcc[getFileName(s.name)] += s.risk_cc;			
			pfmaxriskcc[getFileName(s.name)] =  pfmaxriskcc[getFileName(s.name)] > s.risk_cc ? pfmaxriskcc[getFileName(s.name)] : s.risk_cc;
			pfcomplexity[getFileName(s.name)] = pfcomplexity[getFileName(s.name)] + s.complexity;
		} else {
			pfsize[getFileName(s.name)] = s.size;
			pfpath[getFileName(s.name)] = getPath(s.name);
			pfmethods[getFileName(s.name)] = 1;
			pfriskcc[getFileName(s.name)] = s.risk_cc;
			pfmaxriskcc[getFileName(s.name)] = s.risk_cc;
			pfcomplexity[getFileName(s.name)] = s.complexity;
		}		
	}
	
	for (pf <- pfsize) {
		pfs += <pf, pfpath[pf], pfsize[pf], pfcomplexity[pf], pfmethods[pf], pfriskcc[pf], pfmaxriskcc[pf]>;
	}
	
 return pfs;
}

public bool increasing2(tuple[str name, int size, int complexity, int methodCount, int riskcc, int maxriskcc] x, tuple[str name, int size, int complexity, int methodCount, int riskcc, int maxriskcc] y ) {
	return x.size > y.size;
}

private str getFileName(str s) {
	return getFileName(toLocation(s));
}

private str getFileName(loc s) {
	str inputString = s.path;
	int tmp = findFirst(inputString, "(");
	str sToDisplay = tmp > -1 ? substring(inputString, 0, tmp) : inputString;
	int lastSlash = findLast(sToDisplay, "/");
	sToDisplay = substring(sToDisplay, 0, lastSlash);
	sToDisplay = substring(sToDisplay, findLast(sToDisplay, "/")+1);
	
	return sToDisplay;
}

private str getPath(loc s) {
	str inputString = s.path;
	int tmp = findFirst(inputString, "(");
	str sToDisplay = tmp > -1 ? substring(inputString, 0, tmp) : inputString;
	int lastSlash = findLast(sToDisplay, "/");
	sToDisplay = substring(sToDisplay, 0, lastSlash+1);	
	return sToDisplay;
}

private str clearString(loc s) {
	str inputString = s.path;
	int lastSlash = findLast(inputString, "/");
	str sToDisplay = substring(inputString, lastSlash+1);
	sToDisplay = substring(sToDisplay, 0, findFirst(sToDisplay, "("));
	
	return sToDisplay;
}
