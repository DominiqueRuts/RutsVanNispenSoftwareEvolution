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
public void displayDashboard(ProjectSummary psum) {
	str pname = psum.projectname + "-dashboard";
	Figure top      = getTop(psum);
	Figure middle_t = getMiddleTop(); 
	Figure middle_b = getMiddleBottom(psum);
	Figure bottom_t = getBottomTop();
	Figure bottom   = getBottom(psum);
	Figure bottom_b = getBottomBottom();
	
	render(pname, vcat([top, middle_t, middle_b, bottom_t, bottom, bottom_b]));
}

public Figure getTop(ProjectSummary psum) {
	str pname = "Project Overview \'" +  psum.projectname + "\'";	
	Figure b1  = box( text(pname, fontSize(20), fontBold(true)), std(halign(0.1)) );
	Figure b2a = box( text("Overall Rating", fontSize(20), fontBold(true)) );
	Figure b2b = getRating(psum.total_rating);
	Figure b2  = box( hcat([b2a, b2b]) );
	
	//return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"));
	return box(hcat([b1, b2]), vshrink(0.1), fillColor("white"), std(lineColor("white")));
}

public Figure getMiddleTop() {
	Figure b1 = box( text("Code Metrics", fontSize(20)), std(halign(0.05)) );
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
	Figure b2 = box( text("Unit Complexity", fontSize(20), left()) );
	Figure b3 = box( text("Architecture", fontSize(20), left()) );
	
	//return box(hcat([b1, b2, b3]), std(halign(0.1)), vshrink(0.1), fillColor("white"));
	return box(hcat([b1, b2, b3]), std(halign(0.1)), vshrink(0.1), std(fontBold(true)), fillColor("white"), std(lineColor("white")));
}

alias ScaleTable = tuple[real s_low, real s_mod, real s_hig, real s_vhi, real a_low, real a_mod, real a_hig, real a_vhi];

public Figure getBottom(ProjectSummary psum) {

	// calculate scaling and offset for size diagram
	ScaleTable st = getScaling(psum.size_profile, 0.15);
		
    Figure L = overlay([box(hshrink(st.s_low), halign(st.a_low), fillColor("Green"), lineColor("Green"), popup("low risk: <psum.size_profile.low_per>%")), 
							  box(hshrink(st.s_mod), halign(st.a_mod), fillColor("Yellow"), lineColor("Yellow"), popup("moderate risk: <psum.size_profile.moderate_per>%")),
							  box(hshrink(st.s_hig), halign(st.a_hig), fillColor("Orange"), lineColor("Orange"), popup("high risk: <psum.size_profile.high_per>%")),
							  box(hshrink(st.s_vhi), halign(st.a_vhi), fillColor("Red"), lineColor("Red"), popup("very high risk: <psum.size_profile.very_high_per>%"))
 					   ]);
                     
	// calculate scaling and offset for complexity diagram
	st = getScaling(psum.cc_profile, 0.15);
	
	Figure C = overlay([box(hshrink(st.s_low), halign(st.a_low), fillColor("Green"), lineColor("Green"), popup("low risk: <psum.cc_profile.low_per>%")), 
							  box(hshrink(st.s_mod), halign(st.a_mod), fillColor("Yellow"), lineColor("Yellow"), popup("moderate risk: <psum.cc_profile.moderate_per>%")),
							  box(hshrink(st.s_hig), halign(st.a_hig), fillColor("Orange"), lineColor("Orange"), popup("high risk: <psum.cc_profile.high_per>%")),
							  box(hshrink(st.s_vhi), halign(st.a_vhi), fillColor("Red"), lineColor("Red"), popup("very high risk: <psum.cc_profile.very_high_per>%"))
							 ]);
							 
	Figure R = vcat([box(text("Files		: <psum.files>", fontSize(20)), std(left())), 
					 box(text("Methods	: <psum.methods>", fontSize(20)), std(left())), 
					 box(text("Lines of Code	: <psum.volume>", fontSize(20)), std(left()))]);
	
	//return box(hcat([L, C, R]), vshrink(0.25), fillColor("white"));
	return box(hcat([L, C, R]), vshrink(0.25), fillColor("white"), std(lineColor("white")));
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

public Figure getBottomBottom() {	
	int a = 150, b = 30, n = 0;
	 
	Figure b1 = button("View Size", void(){n += 1;}, halign(0.1), size(a, b), resizable(false, false));
	Figure b2 = button("View Complexity", void(){n += 1;}, halign(0.0), size(a, b), resizable(false, false));
	Figure b3 = button("View Filetree", void(){n += 1;}, halign(0.0), size(a, b), resizable(false, false));
	
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

public void visualize(list[MethodStat] ProjectStat_sorted_loc) {
	println("Start visualization...");
	cscale = colorScale(ProjectStat_sorted_loc.complexity, color("green", 0.5), color("red", 0.8));
	//list[loc] names = ProjectStat_sorted_loc.name;	
	t = treemap([
	     box(area(s.size),fillColor(cscale(s.complexity)),popup("Object: <s.name> \nSize: <s.size> \nComplexity: <s.complexity>")

//onMouseDown(bool (int butnr, map[KeyModifier,bool] modifiers) { 
//                                                 println("<ProjectStat_sorted_loc[i].name> - Size: <s.size> - Complexity: <s.complexity>"); 
//                                                 return true;
//                                             } )
                         )  | s <- ProjectStat_sorted_loc, s.complexity > 2 //, i <- [0..size(ProjectStat_sorted_loc)]
     ] );
	render(t);
	println("End visualization...");
}

FProperty popup(str S){
 return mouseOver(box(text(S), size(50), fillColor("lightyellow"),
 grow(1.2),resizable(false)));
}