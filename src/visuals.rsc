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

import IO;

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
	
	//return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"));
	return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"), std(lineColor("white")));
}

public Figure getMiddleTop() {
	Figure b1 = box( text("Code Metrics (SiG Criteria)", fontSize(20)), std(halign(0.06)) );
	Figure b2 = box( text("ISO9126 Quality Rating", fontSize(20)), std(halign(0.1)) );
	
	//return box(hcat([b1, b2]), std(right()), vshrink(0.1), fillColor("white"));
	return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"), std(lineColor("white")));
}

public Figure getMiddleBottom(ProjectSummary psum) {
	Figure b1 = getRatingMatrix("Volume", "Code Duplication", "Unit Size", "Unit Complexity", psum.vol_rating, psum.dup_rating, psum.size_rating, psum.cc_rating);
	Figure b2 = getRatingMatrix("Analysability", "Changability", "Stability", "Testability", psum.analysability, psum.changability, psum.stability, psum.testability);
	
	//return box(hcat([b1, b2]), vshrink(0.35), fillColor("white"));
	return box(hcat([b1, b2]), vshrink(0.35), fillColor("white"), std(lineColor("white")));
}

public Figure getBottomTop() {	
	Figure b1 = box( text("Unit Size", fontSize(20)) );
	Figure b2 = box( text("Unit Complexity", fontSize(20), halign(0.05)) );
	Figure b3 = box( text("Architecture", fontSize(20), halign(0.03)) );
	
	//return box(hcat([b1, b2, b3]), std(halign(0.1)), vshrink(0.1), fillColor("white"));
	return box(hcat([b1, b2, b3]), std(halign(0.05)), vshrink(0.1), std(fontBold(true)), fillColor("white"), std(lineColor("white")));
}

alias ScaleTable = tuple[real s_low, real s_mod, real s_hig, real s_vhi, real a_low, real a_mod, real a_hig, real a_vhi];

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
	
	//return box(hcat([L, C, R]), vshrink(0.25), fillColor("white"));
	return box(hcat([L0, L, C, R]), vshrink(0.25), fillColor("white"), std(lineColor("white")));
}

public ScaleTable getScaling(RiskProfile rp, real offset) {
	real al = offset;
	real sc = (1.0 - al) - al; 
	
	real s_low = sc*(rp.low_per/100.0);
	real s_mod = sc*(rp.moderate_per/100.0);
	real s_hig = sc*(rp.high_per/100.0);
	real s_vhi = sc*(rp.very_high_per/100.0);
	
	real a_low = al;
	real a_mod = a_low + s_low;
	real a_hig = a_mod + s_mod;
	real a_vhi = a_hig + s_hig;
	
	//println("s_low: <s_low>, s_mod: <s_mod>, s_hig: <s_hig>, s_vhi: <s_vhi>, a_low: <a_low>, a_mod: <a_mod>, a_hig: <a_hig>, a_vhi: <a_vhi>");
	
	return <s_low, s_mod, s_hig, s_vhi, a_low, a_mod, a_hig, a_vhi>;
}

public Figure getBottomBottom(ProjectSummary psum, ProjectFilesStats pfs, list[MethodStat] pms) {	
	int a = 150, b = 30, n = 0;
	 
	Figure b1 = button("Unit Size Treemap", void(){displayUnitSize(psum, pms);}, halign(0.075), size(a, b), resizable(false, false));
	Figure b2 = button("File Size Treemap", void(){displayFileSize(psum, pfs);}, halign(0.05), size(a, b), resizable(false, false));
	Figure b3 = button("View Filetree", void(){n += 1;}, halign(0.03), size(a, b), resizable(false, false));
	
	//return box(hcat([b1, b2, b3]), vshrink(0.1), fillColor("white"));
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
	Figure b2 = box( text(b, fontSize(15), left()) );

	return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"), std(lineColor("white")));
}

public void displayUnitSize(ProjectSummary psum, list[MethodStat] ProjectStat_sorted_loc) {
	str pname = psum.projectname + " - unit size treemap";
	list[MethodStat] pms = ProjectStat_sorted_loc;	
	t = treemap([ box(area(s.size), fillColor(getColor(s.risk_cc)), popup("Object: <s.name>\nSize: <s.size>\nComplexity: <s.complexity>")
                 , execOnMouseDown("name: <s.name>, complexity: <s.complexity>, size: <s.size>") ) | s <- pms, s.size > 10
                ], vshrink(0.9), hshrink(0.975));
                
	render(pname, vcat([getHeaderView(psum, "Unit Size Treemap", "box area = unit size, box color = unit complexity"), t]));
}

public void displayFileSize(ProjectSummary psum, ProjectFilesStats pfs) {
	str pname = psum.projectname + " - file size treemap";
	cscale = colorScale(pfs.complexity, color("green"), color("darkred"));
    t = treemap([ box(area(s.size), fillColor(cscale(s.complexity)), popup("Object: <s.file>\nComplexity: <s.complexity>\nSize: <s.size>")
                , execOnMouseDown("name: <s.file>, complexity: <s.complexity>, size: <s.size>") ) | s <- pfs, s.size > 10
                ], vshrink(0.9), hshrink(0.975));
                
	render(pname, vcat([getHeaderView(psum, "File Size Treemap", "box area = file size, box color = file complexity"), t]));
}

FProperty popup(str S){
 return mouseOver(box(text(S), size(50), fillColor("lightyellow"),
 grow(1.2),resizable(false)));
}

FProperty execOnMouseDown(str info) {
return onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) {
     println("<info>");
     return true;
  });
}

alias ProjectFilesStats = list[tuple[str file, int size, int complexity, int methodCount, int riskcc, int maxriskcc]];
alias ProjectFilesStat = tuple[str file, int size, int complexity, int methodCount, int riskcc, int maxriskcc];
alias ProjectFilesSize = map[str file, int size];
alias ProjectFilesMethods = map[str file, int methods];
alias ProjectFilesRiskCC = map[str file, int riskCC];
alias ProjectFilesMaxRiskCC = map[str file, int maxriskcc];
alias ProjectFilesComplexity = map[str file, int complexity];

private ProjectFilesStats getProjectFileStats(list[MethodStat] ProjectStat_sorted_loc) {
	ProjectFilesStats pfs = [];
	ProjectFilesSize pfsize = ();
	ProjectFilesMethods pfmethods = ();
	ProjectFilesRiskCC pfriskcc = ();
	ProjectFilesMaxRiskCC pfmaxriskcc = ();
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
			pfmethods[getFileName(s.name)] = 1;
			pfriskcc[getFileName(s.name)] = s.risk_cc;
			pfmaxriskcc[getFileName(s.name)] = s.risk_cc;
			pfcomplexity[getFileName(s.name)] = s.complexity;
		}
	}
	
	for (pf <- pfsize) {
		pfs += <pf, pfsize[pf], pfcomplexity[pf], pfmethods[pf], pfriskcc[pf], pfmaxriskcc[pf]>;
	}
	
	pfs = sort(pfs, increasing2);
	
 return pfs;
}

public bool increasing2(tuple[str name, int size, int complexity, int methodCount, int riskcc, int maxriskcc] x, tuple[str name, int size, int complexity, int methodCount, int riskcc, int maxriskcc] y ) {
	return x.size > y.size;
}

private str getFileName(loc s) {
	str inputString = s.path;
	int lastSlash = findLast(inputString, "/");
	str sToDisplay = substring(inputString, 0, lastSlash);
	sToDisplay = substring(sToDisplay, findLast(sToDisplay, "/")+1);
	
	return sToDisplay;
}
